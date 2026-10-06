part of 'app_shell.dart';

class _GasReportScreen extends StatefulWidget {
  final AppSession session;
  final ValueChanged<int> onNavigate;
  const _GasReportScreen({required this.session, required this.onNavigate});
  @override
  State<_GasReportScreen> createState() => _GasReportScreenState();
}

class _GasReportScreenState extends State<_GasReportScreen> {
  static const gold = _CinematicMore.gold;
  static const muted = Color(0xFFA9B2B6);
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  GasReport? _report;
  String? _error, _keptSignature;
  bool _distance = false, _busy = false, _expanded = false;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    TestStore.revision.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    TestStore.revision.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final request = ++_request;
    try {
      final report = await GasReportRepository.load(_month);
      if (mounted && request == _request) {
        setState(() {
          _report = report;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && request == _request) {
        setState(() => _error = 'Не удалось загрузить отчёт: $e');
      }
    }
  }

  String _number(double v) {
    final value = v.abs() < 0.0000001 ? 0.0 : v;
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '')
        .replaceAll('.', ',')
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m)=>'${m[1]} ');
  }

  String _litres(double? v) => v == null ? '—' : '${_number(v)} л';
  String _monthName(DateTime d) => '${_garageMonths[d.month - 1]} ${d.year}';
  void _move(int delta) {
    if (_busy) {
      return;
    }
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _report = null;
      _error = null;
      _keptSignature = null;
    });
    _reload();
  }

  void _notice(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _commit(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      await _reload();
    } catch (e) {
      _notice(
        e.toString().replaceFirst(
          RegExp(r'^(Bad state: |Invalid argument\(s\): )'),
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _panel(
    Widget child, {
    EdgeInsets padding = const EdgeInsets.all(14),
  }) => _GasMetalSurface(
    padding: padding,
    child: child,
  );
  Widget _action(
    String label,
    VoidCallback? onPressed, {
    IconData? icon,
  }) => TextButton(
    style: TextButton.styleFrom(
      foregroundColor: gold,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Flexible(child: Text(label)),
      ],
    ),
  );
  Future<void> _opening(GasReport report) async {
    final controller = TextEditingController(
      text: report.opening == null ? '' : _number(report.opening!),
    );
    String? error;
    final result = await showDialog<Object>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          backgroundColor: const Color(0xFF10191E),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: const BorderSide(color: Color(0xFF776044), width: .8),
          ),
          title: const Text(
            'Начальный остаток',
            style: TextStyle(color: Color(0xFFF1EEE6), fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Остаток газа с прошлого месяца',
                style: TextStyle(color: muted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  suffixText: 'л',
                  errorText: error,
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF5A656B)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: gold),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (report.manualOpening && report.carriedOpening != null)
                _action(
                  'Использовать перенос: ${_litres(report.carriedOpening)}',
                  () => Navigator.pop(dialog, 'carry'),
                ),
            ],
          ),
          actions: [
            _action('Отмена', () => Navigator.pop(dialog)),
            _action('Сохранить', () {
              final value = double.tryParse(
                controller.text.trim().replaceAll(' ', '').replaceAll(',', '.'),
              );
              if (value == null || !value.isFinite || value < 0) {
                update(() => error = 'Введите число не меньше нуля');
                return;
              }
              Navigator.pop(dialog, value);
            }),
          ],
        ),
      ),
    );
    // Let the dialog finish its closing transition before disposing its field.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (!mounted || result == null) {
      return;
    }
    await _commit(
      () => result == 'carry'
          ? GasReportRepository.useCarry(report.month)
          : GasReportRepository.setOpening(report.month, result as double),
    );
  }

  Future<void> _submit(GasReport report) async {
    final next = DateTime(report.month.year, report.month.month + 1);
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: const Color(0xFF10191E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: Color(0xFF776044), width: .8),
        ),
        title: const Text(
          'Подтверждение',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        content: Text(
          '${report.submitted ? 'Обновить сданный отчёт' : 'Отметить отчёт'} за ${_monthName(report.month)}${report.submitted ? '?' : ' как сданный?'}\n\n'
          'Остаток ${_litres(report.closing)} будет перенесён в ${_monthName(next)} как начальный остаток. '
          'Если в следующем месяце указан ручной остаток, он сохранится до отмены ручной корректировки.',
          style: const TextStyle(
            color: Color(0xFFD5DADC),
            height: 1.4,
            fontSize: 15,
          ),
        ),
        actions: [
          _action('Отмена', () => Navigator.pop(dialog, false)),
          _action(
            report.submitted ? 'Обновить перенос' : 'Да, отчёт сдан',
            () => Navigator.pop(dialog, true),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await _commit(
        () => GasReportRepository.submit(
          report.month,
          expectedSignature: report.signature,
        ),
      );
    }
  }

  Widget _stat(String label,String value,IconData icon,{String? note,Color color=gold,VoidCallback? onTap}) {
    final content=_GasMetalSurface(
      compact:true,
      padding:const EdgeInsets.fromLTRB(11,13,11,13),
      child:Row(children:[
          SizedBox(width:30,height:39,
            child:Icon(icon,color:color,size:25,shadows:const [Shadow(color:Color(0xAA000000),offset:Offset(1,2),blurRadius:2)])),
          const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(label,style:const TextStyle(color:Color(0xFFCBD2D4),fontSize:11,height:1.25)),
            const SizedBox(height:6),FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,
              child:Text(value,maxLines:1,style:const TextStyle(color:Color(0xFFF0F1EF),fontSize:20,fontWeight:FontWeight.w600))),
            if(note!=null)Padding(padding:const EdgeInsets.only(top:4),child:Text(note,style:const TextStyle(color:muted,fontSize:9,height:1.2))),
          ])),
        ]));
    return onTap==null?content:InkWell(borderRadius:BorderRadius.circular(11),onTap:onTap,child:content);
  }
  Widget _summary(GasReport r)=>_panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('Итоги месяца',style:TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w600)),const SizedBox(height:12),
    IntrinsicHeight(child:Row(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Expanded(child:_stat('Остаток\nс прошлого месяца',_litres(r.opening),Icons.propane_tank_outlined,onTap:_busy?null:()=>_opening(r))),
      const SizedBox(width:8),Expanded(child:_stat('Получено газа\nза месяц',_litres(r.gas),Icons.propane_tank_outlined)),
    ])),const SizedBox(height:8),
    IntrinsicHeight(child:Row(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Expanded(child:_stat('Пробег за месяц','${_number(r.km)} км',Icons.add_road_outlined,color:const Color(0xFFB9B7AE))),
      const SizedBox(width:8),Expanded(child:_stat('Расход по норме',_litres(r.consumption),Icons.local_fire_department_outlined,
        color:const Color(0xFFB9B7AE),note:'Норма 28 л / 100 км')),
    ])),const SizedBox(height:9),
    _GasMetalSurface(compact:true,padding:const EdgeInsets.symmetric(horizontal:13,vertical:12),
      child:Row(children:[Icon(Icons.propane_tank_outlined,color:(r.closing??0)<0?const Color(0xFFD29280):const Color(0xFF86B7A2),size:32),
        const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Текущий остаток',style:TextStyle(color:Color(0xFFD1DFDA),fontSize:13)),const SizedBox(height:4),
          Text(_litres(r.closing),style:TextStyle(color:(r.closing??0)<0?const Color(0xFFD29280):const Color(0xFF80B79B),fontSize:27,fontWeight:FontWeight.w600)),
        ])),const SizedBox(width:83,height:60,child:Icon(Icons.local_fire_department_outlined,color:Color(0x888F918D),size:44))])),
    if((r.closing??0)<0)const Padding(padding:EdgeInsets.only(top:8),child:Text('Отрицательный остаток: проверьте выдачи и начальный остаток.',style:TextStyle(color:Color(0xFFD29280),fontSize:12))),
    if(r.opening==null)_action('Указать остаток с прошлого месяца',_busy?null:()=>_opening(r),icon:Icons.edit_outlined)
    else Padding(padding:const EdgeInsets.only(top:7),child:Text('Нажмите на начальный остаток, чтобы изменить его.',style:const TextStyle(color:muted,fontSize:10))),
  ]),padding:const EdgeInsets.all(10));
  Widget _status(GasReport r) {
    final kept = _keptSignature == r.signature;
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.changed) ...[
            const Text(
              'Данные сданного отчёта изменились',
              style: TextStyle(
                color: gold,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Сохранённый перенос: ${_litres(r.fixedClosing)}. Текущий расчёт: ${_litres(r.closing)}.',
              style: const TextStyle(color: muted, fontSize: 13),
            ),
            _action(
              'Пересчитать остаток и обновить перенос в следующий месяц',
              _busy || r.pending > 0 || r.opening == null
                  ? null
                  : () => _submit(r),
              icon: Icons.refresh,
            ),
            if (!kept)
              _action(
                'Оставить прежний перенос',
                () => setState(() => _keptSignature = r.signature),
              ),
            if (kept)
              const Text(
                'Прежний перенос сохранён.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
          ] else if (r.submitted) ...[
            Row(
              children: [
                const Icon(Icons.check, size: 18, color: Color(0xFF8AA394)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Отчёт сдан · ${_detailDate(r.submittedAt!)}',
                    style: const TextStyle(
                      color: Color(0xFFC9D5CC),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Зафиксированный остаток: ${_litres(r.fixedClosing)}',
              style: const TextStyle(color: muted, fontSize: 13),
            ),
          ] else
            _action(
              'Отчёт сдан',
              _busy || r.pending > 0 || r.opening == null
                  ? null
                  : () => _submit(r),
              icon: Icons.check_circle_outline,
            ),
          if (r.pending > 0)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                'Смен без окончательного пробега или незавершённых: ${r.pending}. Завершите их перед сдачей отчёта.',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ),
          if (r.opening == null)
            const Text(
              'Для сдачи укажите начальный остаток.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
        ],
      ),
    );
  }

  void _toggleTable()=>setState(()=>_expanded=!_expanded);
  Widget _table(GasReport r){
    final rows=_expanded?r.days:r.days.take(5).toList();
    final distance=_expanded&&_distance;
    Widget cell(String value,{bool header=false,bool total=false,bool left=false})=>Padding(
      padding:EdgeInsets.symmetric(horizontal:3,vertical:header?8:6),
      child:Text(value,textAlign:left?TextAlign.left:TextAlign.center,softWrap:true,
        style:TextStyle(color:header?const Color(0xFFBDC7CB):total?gold:const Color(0xFFE3E8E9),
          fontSize:header?9.5:10.5,height:1.2,fontWeight:total?FontWeight.w600:FontWeight.w400)));
    TableRow line(List<String> values,{bool header=false,bool total=false,GasReportDay? day})=>TableRow(
      decoration:BoxDecoration(color:header?const Color(0x70111B20):total?const Color(0x9910191C):Colors.transparent),
      children:[for(var i=0;i<values.length;i++)
        if(day!=null)InkWell(onTap:()=>_openDaySummary(context,day.date),
          child:cell(values[i],left:i==values.length-1))
        else cell(values[i],header:header,total:total,left:i==values.length-1),
      ]);
    return _panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.fromLTRB(10,5,8,5),child:Row(children:[
        Expanded(child:Text(_expanded?'Журнал за месяц':'По дням',style:const TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.w600))),
        OutlinedButton(onPressed:_toggleTable,style:OutlinedButton.styleFrom(foregroundColor:gold,
          side:const BorderSide(color:Color(0xFF997B48),width:.8),backgroundColor:const Color(0x303F301B),
          shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(9)),padding:const EdgeInsets.symmetric(horizontal:10)),
          child:Text(_expanded?'Свернуть ↙':'Развернуть ↗',style:const TextStyle(fontSize:12))),
      ])),
      if(_expanded)Padding(padding:const EdgeInsets.fromLTRB(5,0,5,8),child:Row(children:[
        for(final mode in [false,true])Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:TextButton(
          onPressed:()=>setState(()=>_distance=mode),
          style:TextButton.styleFrom(foregroundColor:_distance==mode?gold:muted,
            backgroundColor:_distance==mode?const Color(0x664B391E):const Color(0x99081015),
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(7),side:BorderSide(color:_distance==mode?const Color(0xFFA78951):const Color(0xFF39464C),width:.8)),
            padding:const EdgeInsets.symmetric(horizontal:4,vertical:10)),
          child:Text(mode?'Пробег за день':'Показания одометра',textAlign:TextAlign.center,style:const TextStyle(fontSize:11))))),
      ])),
      Padding(padding:const EdgeInsets.symmetric(horizontal:6),child:Table(
        defaultVerticalAlignment:TableCellVerticalAlignment.middle,
        border:TableBorder.all(color:const Color(0xFF28343A),width:.5,borderRadius:BorderRadius.circular(7)),
        columnWidths:distance?const {0:FlexColumnWidth(12),1:FlexColumnWidth(21),2:FlexColumnWidth(12),3:FlexColumnWidth(13),4:FlexColumnWidth(42)}:
          const {0:FlexColumnWidth(11),1:FlexColumnWidth(17),2:FlexColumnWidth(17),3:FlexColumnWidth(10),4:FlexColumnWidth(11),5:FlexColumnWidth(34)},
        children:[
          line(['Дата',if(distance)'Пробег\nза день, км'else ...['Начало,\nкм','Конец,\nкм'],'Газ,\nл','Бензин,\nл','Направление'],header:true),
          for(final d in rows)line([
            '${d.date.day.toString().padLeft(2,'0')}.${d.date.month.toString().padLeft(2,'0')}',
            if(distance)'${_number(d.km)}${d.pending>0?' *':''}'else ...[d.startKm==null?'—':_number(d.startKm!),d.endKm==null?'—':_number(d.endKm!)],
            d.gas==0?'—':_number(d.gas),d.petrol==0?'—':_number(d.petrol),d.directions.isEmpty?'—':d.directions,
          ],day:d),
          if(_expanded)line(['Итого',_number(r.km),if(!distance)'км',_number(r.gas),_number(r.petrol),''],total:true),
        ],
      )),
      if(r.days.isEmpty)const Padding(padding:EdgeInsets.all(16),child:Text('В этом месяце смен пока нет.',style:TextStyle(color:muted,fontSize:12))),
      if(!_expanded&&r.days.isNotEmpty)TextButton(onPressed:_toggleTable,style:TextButton.styleFrom(foregroundColor:muted),
        child:Text('Показано ${rows.length} из ${r.days.length} дней ⌄',style:const TextStyle(fontSize:10))),
      if(_expanded)const Padding(padding:EdgeInsets.all(10),child:Text('Нажмите строку, чтобы открыть сводку дня',style:TextStyle(color:muted,fontSize:10))),
      if(r.pending>0)const Padding(padding:EdgeInsets.all(10),child:Text('* Учтён только сохранённый пробег; итог незавершённых смен может измениться.',style:TextStyle(color:muted,fontSize:10))),
    ]),padding:EdgeInsets.zero);
  }
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now(), r = _report;
    final canNext = _month.isBefore(DateTime(now.year, now.month));
    return PopScope(canPop: !_expanded,onPopInvokedWithResult:(didPop,result){
      if(!didPop&&_expanded){_toggleTable();}
    },child:AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF080E12),
        body: Stack(
          children: [
            _CinematicMore.backdrop(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xC010161A),
                            border: Border.all(color: gold, width: .8),
                          ),
                          child: IconButton(
                            tooltip: 'Назад',
                            onPressed: () { if(_expanded){_toggleTable();}else{Navigator.pop(context);} },
                            icon: const Icon(Icons.chevron_left, color: gold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Отчёт за газ',
                            style: TextStyle(
                              color: Color(0xFFF1EEE6),
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: _panel(
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Предыдущий месяц',
                            onPressed: _busy ? null : () => _move(-1),
                            icon: const Icon(Icons.chevron_left, color: gold),
                          ),
                          Expanded(
                            child: Text(
                              _monthName(_month),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Следующий месяц',
                            onPressed: canNext && !_busy
                                ? () => _move(1)
                                : null,
                            icon: Icon(
                              Icons.chevron_right,
                              color: canNext ? gold : const Color(0xFF4B5357),
                            ),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: _error != null
                        ? Center(
                            child: _panel(
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _error!,
                                    style: const TextStyle(color: muted),
                                  ),
                                  _action('Повторить', _reload),
                                ],
                              ),
                            ),
                          )
                        : r == null
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: gold,
                              strokeWidth: 2,
                            ),
                          )
                        : ListView(
                            key:ValueKey(_expanded),
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                            children: [
                              if(!_expanded)...[_summary(r),const SizedBox(height:12)],
                              _table(r),
                              if(!_expanded)...[const SizedBox(height:12),_status(r)],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}


// Reuse the approved Work artwork directly. Nine-slice drawing preserves the
// metal corners and rim thickness while the report keeps its adaptive layout.
class _GasMetalSurface extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool compact;
  const _GasMetalSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.compact = false,
  });

  @override
  State<_GasMetalSurface> createState() => _GasMetalSurfaceState();
}

class _GasMetalSurfaceState extends State<_GasMetalSurface> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _artwork;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = const AssetImage(
      'assets/images/scenes/work_shift_scene.png',
    ).resolve(createLocalImageConfiguration(context));
    if (_stream?.key == stream.key) return;
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = stream;
    _listener = ImageStreamListener((info, synchronousCall) {
      final previous = _artwork;
      setState(() => _artwork = info);
      previous?.dispose();
    });
    stream.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _artwork?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _GasMetalPainter(_artwork, compact: widget.compact),
    child: Padding(padding: widget.padding, child: widget.child),
  );
}

class _GasMetalPainter extends CustomPainter {
  final ImageInfo? artwork;
  final bool compact;
  const _GasMetalPainter(this.artwork, {required this.compact});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final image = artwork?.image;
    if (image == null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
        Paint()..color = const Color(0xFF141719),
      );
      return;
    }
    // Source bounds include the complete rim, without neighbouring panels.
    final source = compact
        ? const Rect.fromLTRB(18, 632, 302, 844)
        : const Rect.fromLTRB(17, 1057, 837, 1567);
    final sx = image.width / 852;
    final sy = image.height / 1846;
    const corner = 34.0;
    final edge = math.min(14.0, math.min(size.width, size.height) / 2);
    final xs = [source.left, source.left + corner, source.right - corner, source.right];
    final ys = [source.top, source.top + corner, source.bottom - corner, source.bottom];
    final dx = [0.0, edge, size.width - edge, size.width];
    final dy = [0.0, edge, size.height - edge, size.height];
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      // Neutral graphite surfaces and warm metal, matching the Home panels.
      // Mix the blue reflections toward grey without tinting text or status colours.
      ..colorFilter = const ColorFilter.matrix(<double>[
        .84, .12, .04, 0, 0,
        .08, .70, .06, 0, 0,
        .04, .40, .24, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 3; column++) {
        canvas.drawImageRect(
          image,
          Rect.fromLTRB(xs[column] * sx, ys[row] * sy,
              xs[column + 1] * sx, ys[row + 1] * sy),
          Rect.fromLTRB(dx[column], dy[row], dx[column + 1], dy[row + 1]),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GasMetalPainter oldDelegate) =>
      oldDelegate.artwork != artwork || oldDelegate.compact != compact;
}
