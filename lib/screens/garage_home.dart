part of 'app_shell.dart';

// Approved composition: 840 × 1870. Background and controls share coordinates.
// Widgets remain live; artwork contains only garage, truck and wall lettering.
const _amber = Color(0xFFFFBB4D);
const _ice = Color(0xFF22DCEF);
const _paper = Color(0xFFEDEFF2);
const _garageMonths = ['Январь','Февраль','Март','Апрель','Май','Июнь',
  'Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'];

class _ReferenceHomeDashboard extends StatelessWidget {
  final AppSession session;
  final _HomeMonthData data;
  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;
  final Size size;
  final ValueChanged<int> onNavigate;
  final VoidCallback onQuickAdd;
  const _ReferenceHomeDashboard({required this.session, required this.data,
    required this.month, required this.onMonthChanged, required this.size,
    required this.onNavigate, required this.onQuickAdd});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final scale = size.width / 840;
    // Short devices still fit the whole composition; only very short landscape
    // windows scroll, so controls are never clipped or made microscopically small.
    final height = math.max(1450.0, (size.height - bottom) / scale);
    final sy = height / 1870;
    Widget place(double x, double y, double w, double h, Widget child) => Positioned(
      left: x, top: y * sy, width: w, height: h * sy,
      child: FittedBox(fit: BoxFit.contain, alignment: Alignment.center,
        child: SizedBox(width: w, height: h, child: child)));
    void menu() { _openHomeMenu(context, session); }
    void metric(String title, double tonnes) {
      _garageInfo(context, title, '${_fmt1(tonnes)} т за ${_garageMonths[month.month-1].toLowerCase()} ${month.year}',
        'Тоннаж пополняется при добавлении рейса с выбранным типом «$title».');
    }
    final displayName = session.displayName == 'Водитель' ? 'Аркадий' : session.displayName;
    final initials = displayName == 'Аркадий' ? 'АБ' : displayName.trim().split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty).take(2).map((word) => word[0]).join().toUpperCase();
    final canvas = SizedBox(width: 840, height: height, child: Stack(children: [
      Positioned.fill(child: Image.asset('assets/images/garage_approved.png',
        fit: BoxFit.fill, filterQuality: FilterQuality.high)),
      Positioned(left: 0, top: 0, width: 840, height: 355 * sy,
        child: const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xB3000609), Color(0x8800070B), Color(0x0000070B)], stops: [0,.72,1]))))),
      Positioned(left: 0, top: 1120 * sy, width: 840, height: 750 * sy,
        child: const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0x2202070A), Color(0x8802070A), Color(0x6602070A)]))))),
      place(20, 30, 276, 75, _GarageTap(label: 'Профиль', onTap: menu, child: Row(children: [
        Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle,
          color: const Color(0x88080D0E), border: Border.all(color: _amber, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x22FF961C), blurRadius: 14)]),
          child: Center(child: _garageText(initials, 26, weight: FontWeight.w600))),
        const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, children: [
            _garageText(displayName, 24, weight: FontWeight.w600),
            const SizedBox(height: 4), _garageText(session.role.title, 20, color: const Color(0xFFADB4BA))]))]))),
      place(343, 41, 158, 42, Column(children: [
        Transform.scale(scaleX: 1.12, child: const Text('ГАЗЕЛЬ', style: TextStyle(
          color: Color(0xFFB7BEC7), fontSize: 25, letterSpacing: 3,
          fontWeight: FontWeight.w700, fontStyle: FontStyle.italic))),
        const SizedBox(height: 7), Container(width: 68, height: 2, color: _amber)])),
      place(611, 38, 125, 55, const Row(children: [
        _GarageIcon('sun', color: _amber, size: 43), SizedBox(width: 12),
        Text('-12°', style: TextStyle(color: _paper, fontSize: 31, fontWeight: FontWeight.w600))])),
      place(766, 25, 61, 73, _GarageTap(label: 'Уведомления', onTap: () =>
        _garageInfo(context, 'Уведомления', 'Сервис пока не подключён', 'Здесь будут уведомления приложения.'),
        child: const Center(child: _GarageIcon('bellOutline', size: 39)))),
      place(190, 119, 460, 37, Center(child: _garageText('Заработано за месяц', 24, color: const Color(0xFFBCC2C9)))),
      place(263, 155, 317, 63, Center(child: FittedBox(fit: BoxFit.scaleDown,
        child: _garageText('${_fmtInt(data.salary)} ₸', 65, color: _amber, weight: FontWeight.w600)))),
      place(201, 153, 54, 69, _GarageTap(label: 'Предыдущий месяц', onTap: () =>
        onMonthChanged(DateTime(month.year, month.month-1)), child: const Icon(Icons.chevron_left, color: Color(0xFF959DA5), size: 41))),
      place(585, 153, 54, 69, _GarageTap(label: 'Следующий месяц', onTap: () =>
        onMonthChanged(DateTime(month.year, month.month+1)), child: const Icon(Icons.chevron_right, color: Color(0xFF959DA5), size: 41))),
      place(230, 218, 380, 43, _GarageTap(label: 'Выбрать месяц', onTap: () => _chooseMonth(context),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _garageText('${_garageMonths[month.month-1]} ${month.year}', 25),
          const Icon(Icons.expand_more, color: _paper, size: 28)]))),
      place(208, 274, 420, 63, _GarageTap(label: 'Текущая смена', onTap: () => onNavigate(1), child: const _GarageShift())),
      place(2, 139, 106, 675, _GarageRail(onShift: () => onNavigate(1),
        onTrips: () => onNavigate(1), onFuel: () => _openFuelEntry(context),
        onExpenses: onQuickAdd, onStats: () => onNavigate(4))),
      Positioned.fill(child: const IgnorePointer(child: CustomPaint(painter: _GarageLeaders()))),
      place(127, 541, 206, 86, _GarageHud(kind: 'flame', label: 'Газ',
        value: '${_fmt1(data.gas)} л', color: _ice, onTap: () => _openFuelEntry(context))),
      place(119, 810, 212, 85, _GarageHud(kind: 'fuel', label: 'Бензин',
        value: '${_fmt1(data.petrol)} л', color: const Color(0xFFFF6454), onTap: () => _openFuelEntry(context))),
      place(605, 571, 230, 88, _GarageHud(kind: 'city', label: 'Город',
        value: '${_fmt1(data.city)} т', color: _amber, onTap: () => metric('Город',data.city))),
      place(648, 682, 189, 87, _GarageHud(kind: 'district', label: 'Район',
        value: '${_fmt1(data.region)} т', color: const Color(0xFFD58BE8), onTap: () => metric('Район',data.region))),
      place(681, 795, 154, 170, _GarageTap(label: 'Пробег', onTap: () => onNavigate(4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(width: 86, height: 84, child: CustomPaint(painter: _GarageRing(_amber),
            child: Center(child: _GarageIcon('road', color: _amber, size: 42)))),
          const SizedBox(height: 5), _garageText('Пробег', 19),
          FittedBox(fit: BoxFit.scaleDown, child: _garageText('${_fmtInt(data.mileage)} км', 27, weight: FontWeight.w600)),
          _garageText('за месяц', 17)]))),
      place(247, 1106, 355, 44, _GarageOil(login: session.login)),
      place(20, 1175, 287, 223, _GarageSalary(data: data, onTap: () => onNavigate(4))),
      place(317, 1168, 207, 216, _GarageTap(label: 'Завершить смену',
        onTap: () => onNavigate(1), child: const _GarageEndShift())),
      place(533, 1175, 287, 223, const _GarageQuote()),
      place(21, 1420, 798, 153, _GarageTrip(onTap: () => onNavigate(1))),
      place(0, 1626, 840, 150, _GarageNavigation(onWork: () => onNavigate(1),
        onAdd: onQuickAdd, onInvoices: () => onNavigate(3), onMore: menu)),
    ]));
    return ColoredBox(color: const Color(0xFF02070A), child: SingleChildScrollView(
      physics: const ClampingScrollPhysics(), child: Padding(padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(width: size.width, height: height*scale,
          child: FittedBox(fit: BoxFit.fill, alignment: Alignment.topCenter,
            child: MediaQuery.withClampedTextScaling(minScaleFactor: 1, maxScaleFactor: 1, child: canvas))))));
  }

  Future<void> _chooseMonth(BuildContext context) async {
    final selected = await showModalBottomSheet<DateTime>(context: context,
      backgroundColor: const Color(0xFF0C151C), builder: (sheetContext) => SafeArea(
        child: SizedBox(height: 300, child: GridView.count(crossAxisCount: 3,
          childAspectRatio: 2.2, padding: const EdgeInsets.all(16),
          children: List.generate(12, (i) => TextButton(onPressed: () =>
            Navigator.pop(sheetContext, DateTime(month.year,i+1)),
            child: Text(_garageMonths[i], style: TextStyle(color: i+1 == month.month ? _amber : _paper))))))));
    if (selected != null) onMonthChanged(selected);
  }
}

Widget _garageText(String value, double size, {Color color = _paper,
  FontWeight weight = FontWeight.w400, TextAlign align = TextAlign.start}) => Text(value,
    textAlign: align, maxLines: 2, overflow: TextOverflow.ellipsis,
    style: TextStyle(color: color, fontSize: size, height: 1.12, fontWeight: weight,
      letterSpacing: 0, shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 4)]));

class _GarageTap extends StatelessWidget {
  final String label; final VoidCallback onTap; final Widget child;
  const _GarageTap({required this.label, required this.onTap, required this.child});
  @override
  Widget build(BuildContext context) => Semantics(button: true, label: label,
    child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {
      HapticFeedback.selectionClick(); onTap();
    }, child: child));
}

void _garageInfo(BuildContext context, String title, String value, String description) {
  showModalBottomSheet<void>(context: context, backgroundColor: const Color(0xFF0D171E),
    builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(title, style: const TextStyle(fontSize: 22, color: _paper)),
          const SizedBox(height: 16), Text(value, style: const TextStyle(fontSize: 23, color: _amber)),
          const SizedBox(height: 12), Text(description, style: const TextStyle(fontSize: 15, color: _paper))]))));
}

class _GarageGlass extends StatelessWidget {
  final Widget child; final double radius;
  const _GarageGlass({required this.child, this.radius = 20});
  @override
  Widget build(BuildContext context) => Container(decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(radius), border: Border.all(color: const Color(0x88778288)),
    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xBA131D22), Color(0xD5060F14)])),
    child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: child));
}

class _GarageRail extends StatelessWidget {
  final VoidCallback onShift,onTrips,onFuel,onExpenses,onStats;
  const _GarageRail({required this.onShift, required this.onTrips, required this.onFuel,
    required this.onExpenses, required this.onStats});
  @override
  Widget build(BuildContext context) {
    final items=[('shift','Смена',onShift),('truck','Рейсы',onTrips),('fuel','Топливо',onFuel),
      ('expense','Расходы',onExpenses),('chart','Статистика',onStats)];
    return ClipRRect(borderRadius: BorderRadius.circular(22), child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5), child: Container(
        decoration: BoxDecoration(color: const Color(0x40060D12),
          borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x668C969C))),
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for(var i=0;i<items.length;i++) _GarageTap(label: items[i].$2, onTap: items[i].$3,
            child: Container(width: 97, height: 111, decoration: i==0 ? BoxDecoration(
              color: const Color(0x550C0B06), borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _amber, width: 1.6),
              boxShadow: const [BoxShadow(color: Color(0x33FFAF27), blurRadius: 13)]) : null,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                _GarageIcon(items[i].$1, color: i==0 ? _amber : const Color(0xFFB8BDC6), size: 40),
                const SizedBox(height: 15), _garageText(items[i].$2, 18, color: i==0 ? _amber : _paper)])))
        ]))));
  }
}

class _GarageShift extends StatelessWidget {
  const _GarageShift();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 19),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(31),
      border: Border.all(color: _ice, width: 1.5), color: const Color(0xC0042028),
      boxShadow: const [BoxShadow(color: Color(0x3323DDE7), blurRadius: 16)]),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const _GarageIcon('shift', color: _ice, size: 33), const SizedBox(width: 14),
      _garageText('Смена открыта', 23, color: _ice, weight: FontWeight.w500),
      const SizedBox(width: 17), Container(width: 1,height: 28,color: const Color(0x8876DADE)),
      const SizedBox(width: 17), _garageText('02:14:26', 27, color: _ice, weight: FontWeight.w600)]));
}

class _GarageHud extends StatelessWidget {
  final String kind,label,value; final Color color; final VoidCallback onTap;
  const _GarageHud({required this.kind,required this.label,required this.value,required this.color,required this.onTap});
  @override
  Widget build(BuildContext context) => _GarageTap(label: '$label: $value',onTap:onTap,
    child: Row(children: [SizedBox(width: 83,height: 83,child: CustomPaint(painter: _GarageRing(color),
      child: Center(child: _GarageIcon(kind,color:color,size:42)))),
      const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start,
        mainAxisAlignment:MainAxisAlignment.center,children:[_garageText(label,19),
          const SizedBox(height: 4), FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child:_garageText(value,29,weight:FontWeight.w600)),
          const SizedBox(height: 4), _garageText('за месяц',17)]))]));
}

class _GarageRing extends CustomPainter {
  final Color color; const _GarageRing(this.color);
  @override
  void paint(Canvas canvas,Size size) {
    final center=Offset(size.width/2,size.height/2);
    final radius=math.min(size.width,size.height)/2-4;
    final rect=Rect.fromCircle(center:center,radius:radius);
    canvas.drawCircle(center,radius-3,Paint()..color=const Color(0xB308141B));
    for(var i=0;i<28;i++) {
      final a=-math.pi/2+i*math.pi*2/28;
      canvas.drawArc(rect,a,.166,false,Paint()..color=i<23?color:color.withValues(alpha:.22)
        ..style=PaintingStyle.stroke..strokeWidth=6);
    }
  }
  @override
  bool shouldRepaint(_GarageRing old)=>old.color!=color;
}

class _GarageLeaders extends CustomPainter {
  const _GarageLeaders();
  @override
  void paint(Canvas c,Size size) {
    c.save();c.scale(size.width/840,size.height/1870);
    void draw(Color color,List<Offset> points) {
      final path=Path()..moveTo(points.first.dx,points.first.dy);
      for(final p in points.skip(1)){path.lineTo(p.dx,p.dy);}
      c.drawPath(path,Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=1.7);
      c.drawCircle(points.last,4.5,Paint()..color=color);
    }
    draw(_ice,const[Offset(195,622),Offset(219,659),Offset(251,681)]);
    draw(const Color(0xFFFF6454),const[Offset(161,895),Offset(161,914),Offset(205,932)]);
    draw(_amber,const[Offset(607,628),Offset(590,628),Offset(560,678)]);
    draw(const Color(0xFFD58BE8),const[Offset(649,732),Offset(633,732),Offset(621,746)]);
    draw(_amber,const[Offset(682,819),Offset(650,819)]);
    c.restore();
  }
  @override
  bool shouldRepaint(_GarageLeaders old)=>false;
}

class _GarageOil extends StatefulWidget {
  final String login; const _GarageOil({required this.login});
  @override
  State<_GarageOil> createState()=>_GarageOilState();
}
class _GarageOilState extends State<_GarageOil> {
  int remaining=2350;
  String get _key=>'garage_oil_remaining_${widget.login}';
  @override
  void initState(){super.initState();_load();}
  Future<void> _load() async {
    final p=await SharedPreferences.getInstance();
    if(mounted)setState(()=>remaining=p.getInt(_key)??2350);
  }
  Future<void> _edit() async {
    final result=await showDialog<int>(context:context,
      builder: (_) => _GarageOilDialog(initialValue: remaining));
    if(result!=null){
      final p=await SharedPreferences.getInstance();await p.setInt(_key,result);
      if(mounted)setState(()=>remaining=result);
    }
  }
  @override
  Widget build(BuildContext context)=>_GarageTap(label:'До замены масла',onTap:_edit,
    child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
      const _GarageIcon('oil',color:_amber,size:33),const SizedBox(width:14),
      _garageText('До замены масла  ·  ',20),
      Flexible(child:FittedBox(fit:BoxFit.scaleDown,child:Text.rich(TextSpan(children:[
        TextSpan(text:_fmtInt(remaining.toDouble()),style:const TextStyle(color:_amber,fontWeight:FontWeight.w600)),
        const TextSpan(text:' км')]),style:const TextStyle(color:_paper,fontSize:23))))]));
}

class _GarageOilDialog extends StatefulWidget {
  final int initialValue;
  const _GarageOilDialog({required this.initialValue});
  @override
  State<_GarageOilDialog> createState() => _GarageOilDialogState();
}
class _GarageOilDialogState extends State<_GarageOilDialog> {
  late final TextEditingController controller;
  @override
  void initState() { super.initState(); controller = TextEditingController(text: widget.initialValue.toString()); }
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: const Color(0xFF0D171E), title: const Text('Замена масла'),
    content: TextField(controller: controller, autofocus: true, keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(labelText: 'Осталось до замены, км')),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
      TextButton(onPressed: () { final n = int.tryParse(controller.text); if(n != null) Navigator.pop(context,n); },
        child: const Text('Сохранить'))]);
}

class _GarageSalary extends StatelessWidget {
  final _HomeMonthData data;final VoidCallback onTap;
  const _GarageSalary({required this.data,required this.onTap});
  @override
  Widget build(BuildContext context)=>_GarageTap(label:'Заработано сегодня',onTap:onTap,
    child:_GarageGlass(child:Padding(padding:const EdgeInsets.all(21),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[_garageText('Заработано сегодня',20),
        const SizedBox(height:7),FittedBox(fit:BoxFit.scaleDown,child:_garageText('${_fmtInt(data.todaySalary)} ₸',38,weight:FontWeight.w600)),
        const SizedBox(height:12),const Expanded(child:CustomPaint(size:Size(double.infinity,60),painter:_GarageBars())),
        const SizedBox(height:13),ClipRRect(borderRadius:BorderRadius.circular(8),
          child:LinearProgressIndicator(value:(data.todaySalary/40000).clamp(0.0,1.0),
            minHeight:11,color:_amber,backgroundColor:const Color(0xFF303536))),
        const SizedBox(height:12),Row(children:[Expanded(child:_garageText('Цель: 40 000 ₸',18)),
          _garageText('${(data.todaySalary/40000*100).round()}%',18)])]))));
}
class _GarageBars extends CustomPainter {
  const _GarageBars();
  @override
  void paint(Canvas c,Size s){
    const values=[.24,.4,.30,.25,.47,.35,.53,.75,1.0,.47];
    for(var i=0;i<values.length;i++){
      final rect=Rect.fromLTWH(i*s.width/values.length+1,s.height*(1-values[i]),11,s.height*values[i]);
      c.drawRRect(RRect.fromRectAndRadius(rect,const Radius.circular(2)),Paint()..shader=
        const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,
          colors:[Color(0xFFFFD48B),Color(0xFFC17B21),Color(0xFF38230F)]).createShader(rect));
    }
  }
  @override
  bool shouldRepaint(_GarageBars old)=>false;
}
class _GarageEndShift extends StatelessWidget {
  const _GarageEndShift();
  @override
  Widget build(BuildContext context)=>Center(child:Container(width:195,height:195,
    decoration:BoxDecoration(shape:BoxShape.circle,
      border:Border.all(color:const Color(0xFFFFEDD4),width:2.3),
      gradient:const RadialGradient(colors:[Color(0xCC21160B),Color(0xEA080A09),Color(0xED542802)],stops:[0,.85,1]),
      boxShadow:const[BoxShadow(color:Color(0xFFFF890E),blurRadius:8,spreadRadius:2),
        BoxShadow(color:Color(0x66FF7800),blurRadius:22,spreadRadius:7)]),
    child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Container(width:32,height:32,decoration:BoxDecoration(borderRadius:BorderRadius.circular(5),
        border:Border.all(color:const Color(0xFFFFE6AD)),
        gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
          colors:[Color(0xFFFFD980),Color(0xFFFFAF26)]),
        boxShadow:const[BoxShadow(color:Color(0x88FF8D00),blurRadius:20)])),
      const SizedBox(height:21),_garageText('ЗАВЕРШИТЬ\nСМЕНУ',22,align:TextAlign.center)])));
}
class _GarageQuote extends StatelessWidget {
  const _GarageQuote();
  @override
  Widget build(BuildContext context)=>_GarageGlass(child:Stack(children:[
    Positioned.fill(child:Image.asset('assets/images/road_approved.png',fit:BoxFit.cover)),
    const Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(
      begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Color(0xE600080D)],stops:[.25,1])))),
    Positioned(left:21,right:16,bottom:19,child:Text('Дороги не спрашивают,\nкуда ты идёшь.\nОни просто ведут.',
      style:const TextStyle(color:_paper,fontSize:19,height:1.32,
        shadows:[Shadow(color:Colors.black,blurRadius:5)])))
  ]));
}
class _GarageTrip extends StatelessWidget {
  final VoidCallback onTap;const _GarageTrip({required this.onTap});
  @override
  Widget build(BuildContext context)=>_GarageGlass(child:Padding(padding:const EdgeInsets.all(17),
    child:Row(children:[ClipRRect(borderRadius:BorderRadius.circular(17),child:Image.asset(
      'assets/images/road_approved.png',width:143,height:121,fit:BoxFit.cover)),
      const SizedBox(width:23),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
        mainAxisAlignment:MainAxisAlignment.center,children:[_garageText('Текущий рейс',19,color:const Color(0xFFB6BEC5)),
          const SizedBox(height:13),FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,
            child:_garageText('Петропавловск → Кокшетау',26,weight:FontWeight.w600)),
          const SizedBox(height:12),FittedBox(fit:BoxFit.scaleDown,child:_garageText('124 км · 1,8 т · 2 ч 10 мин',21))])),
      const SizedBox(width:15),_GarageTap(label:'Навигация',onTap:onTap,child:Container(width:204,height:77,
        decoration:BoxDecoration(color:const Color(0xA4050C11),borderRadius:BorderRadius.circular(20),
          border:Border.all(color:_amber,width:1.6)),child:Row(mainAxisAlignment:MainAxisAlignment.center,
            children:[const _GarageIcon('navigationOutline',color:_amber,size:38),const SizedBox(width:12),_garageText('Навигация',21)])))
    ])));
}
class _GarageNavigation extends StatelessWidget {
  final VoidCallback onWork,onAdd,onInvoices,onMore;
  const _GarageNavigation({required this.onWork,required this.onAdd,required this.onInvoices,required this.onMore});
  @override
  Widget build(BuildContext context){
    final items=[('homeOutline','Главная',(){}),('map','Карта',onWork),('plus','Добавить',onAdd),
      ('invoice','Накладные',onInvoices),('gridOutline','Ещё',onMore)];
    return Stack(clipBehavior:Clip.none,children:[
      Positioned(left:0,right:0,top:18,bottom:0,child:Container(decoration:const BoxDecoration(
        color:Color(0xCC040B10),border:Border(top:BorderSide(color:Color(0x667C8C94)))),
        child:Row(children:[for(var i=0;i<5;i++)Expanded(child:_GarageTap(label:items[i].$2,
          onTap:items[i].$3,child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
            SizedBox(height:52,child:i==2?null:_GarageIcon(items[i].$1,color:i==0?_amber:_paper,size:44)),
            const SizedBox(height:15),_garageText(items[i].$2,22,color:i==0?_amber:_paper)])))]))),
      Positioned(left:373,top:0,width:94,height:94,child:_GarageTap(label:'Добавить',onTap:onAdd,
        child:Container(decoration:BoxDecoration(shape:BoxShape.circle,
          color:const Color(0xFF070E12),border:Border.all(color:_amber,width:2),
          boxShadow:const[BoxShadow(color:Color(0x44FFA332),blurRadius:14)]),
          child:const Center(child:_GarageIcon('plus',size:43))))),
      Positioned(left:47,bottom:5,width:80,height:2,child:Container(decoration:const BoxDecoration(color:_amber,
        boxShadow:[BoxShadow(color:Color(0xFFFFA32E),blurRadius:9,spreadRadius:2)])))
    ]);
  }
}
class _GarageIcon extends StatelessWidget {
  final String kind; final Color color; final double size;
  const _GarageIcon(this.kind, {this.color = _paper, this.size = 32});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size,
    child: CustomPaint(painter: _GarageIconPainter(kind, color)));
}

// Reference-like line art instead of mixing unrelated Material icon families.
class _GarageIconPainter extends CustomPainter {
  final String kind; final Color color;
  const _GarageIconPainter(this.kind, this.color);
  @override
  void paint(Canvas c, Size s) {
    c.save(); c.scale(s.width/32,s.height/32);
    final p=Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=1.65
      ..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
    final fill=Paint()..color=color;
    void path(List<Offset> pts, {bool close=false, bool solid=false}) {
      final q=Path()..moveTo(pts.first.dx,pts.first.dy);
      for(final v in pts.skip(1)) { q.lineTo(v.dx,v.dy); }
      if(close) q.close(); c.drawPath(q,solid?fill:p);
    }
    void line(double a,double b,double x,double y)=>c.drawLine(Offset(a,b),Offset(x,y),p);
    switch(kind) {
      case 'flame':
        final q=Path()..moveTo(17,1)..cubicTo(16,10,26,12,25,22)
          ..cubicTo(25,28,21,31,18,31)..cubicTo(24,25,15,22,17,16)
          ..cubicTo(12,20,11,27,14,31)..cubicTo(1,29,5,18,9,12)
          ..lineTo(11,18)..cubicTo(11,10,15,7,17,1)..close();
        c.drawPath(q,fill); break;
      case 'fuel':
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4,3,15,26),const Radius.circular(2)),p);
        c.drawRect(const Rect.fromLTWH(7,6,9,8),p); line(2,30,21,30);
        c.drawPath(Path()..moveTo(19,16)..cubicTo(28,14,19,29,26,28)
          ..cubicTo(30,28,27,17,27,13)..lineTo(23,7)..lineTo(22,4),p);
        line(24,7,28,10); break;
      case 'box': case 'expense':
        path(const [Offset(16,2),Offset(28,9),Offset(28,24),Offset(16,31),Offset(4,24),Offset(4,9)],close:true);
        path(const [Offset(4,9),Offset(16,16),Offset(28,9)]); line(16,16,16,31);
        c.drawCircle(const Offset(12,10),1.2,fill); c.drawCircle(const Offset(20,10),1.2,fill);
        c.drawCircle(const Offset(10,20),1.2,fill); c.drawCircle(const Offset(22,20),1.2,fill);
        if(kind=='expense') { line(10,5,23,12); } break;
      case 'pin': case 'route':
        c.drawPath(Path()..moveTo(16,23)..cubicTo(12,17,7,13,9,8)
          ..cubicTo(11,1,22,2,23,9)..cubicTo(24,14,19,20,16,23)..close(),p);
        c.drawCircle(const Offset(16,10),3,fill);
        if(kind=='route') {
          path(const [Offset(5,28),Offset(11,23),Offset(23,29),Offset(29,26)]);
          for(final o in const [Offset(5,28),Offset(23,29),Offset(29,26)]) { c.drawCircle(o,2,fill); }
        } break;
      case 'road':
        line(11,3,3,30);line(21,3,29,30);line(16,4,16,10);line(16,15,16,20);line(16,25,16,30); break;
      case 'truck':
        path(const [Offset(2,5),Offset(20,5),Offset(20,24),Offset(2,24)],close:true);
        path(const [Offset(20,11),Offset(26,11),Offset(30,17),Offset(30,24),Offset(20,24)]);
        line(23,14,23,18);line(23,18,29,18);
        c.drawCircle(const Offset(8,25),3,Paint()..color=const Color(0xFF10151A));c.drawCircle(const Offset(8,25),3,p);
        c.drawCircle(const Offset(25,25),3,Paint()..color=const Color(0xFF10151A));c.drawCircle(const Offset(25,25),3,p);break;
      case 'shift':
        c.drawCircle(const Offset(16,16),13,p);line(16,8,16,17);line(16,17,22,21);break;
      case 'city':
        c.drawRect(const Rect.fromLTWH(4,17,5,12),p);
        c.drawRect(const Rect.fromLTWH(13,4,5,25),p);
        c.drawRect(const Rect.fromLTWH(23,11,5,18),p);
        line(2,30,30,30);line(6.5,20,6.5,25);line(15.5,8,15.5,24);break;
      case 'district':
        path(const [Offset(2,21),Offset(10,10),Offset(15,16),Offset(24,4),Offset(31,12)]);
        path(const [Offset(11,30),Offset(19,16),Offset(22,16),Offset(26,30)]);
        line(20,22,19,27);break;
      case 'oil':
        path(const [Offset(3,9),Offset(18,9),Offset(20,12),Offset(30,8),Offset(25,19),Offset(8,19)],close:true);
        path(const [Offset(3,9),Offset(1,5),Offset(6,5),Offset(10,9)]);
        line(13,8,13,4);line(10,4,16,4);
        c.drawPath(Path()..moveTo(29,22)..quadraticBezierTo(24,28,29,30)
          ..quadraticBezierTo(34,28,29,22)..close(),fill);break;
      case 'homeOutline':
        path(const [Offset(3,14),Offset(16,2),Offset(29,14),Offset(29,30),Offset(19,30),
          Offset(19,21),Offset(13,21),Offset(13,30),Offset(3,30)],close:true);break;
      case 'gridOutline':
        for(final x in [3.0,19.0]) {for(final y in [3.0,19.0]) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,10,10),const Radius.circular(2)),p);
        }}break;
      case 'navigationOutline':
        path(const [Offset(2,14),Offset(29,3),Offset(19,30),Offset(15,18)],close:true);break;
      case 'bellOutline':
        c.drawPath(Path()..moveTo(6,25)..quadraticBezierTo(9,21,9,12)
          ..cubicTo(9,3,23,3,23,12)..quadraticBezierTo(23,21,26,25)..close(),p);
        line(16,2,16,5);c.drawArc(const Rect.fromLTWH(13,25,6,5),0,math.pi,false,p);break;
      case 'chart':
        for(var i=0;i<3;i++) { final top=[13.0,3.0,9.0][i]; c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(5.0+i*9,top,4,29-top),const Radius.circular(2)),fill); } break;
      case 'invoice':
        path(const [Offset(7,2),Offset(20,2),Offset(27,9),Offset(27,30),Offset(7,30)],close:true);
        path(const [Offset(20,2),Offset(20,10),Offset(27,10)]);
        line(12,14,21,14);line(12,19,22,19);line(12,24,20,24);break;
      case 'more':for(final x in [6.0,16.0,26.0]) {c.drawCircle(Offset(x,16),2.2,fill);} break;
      case 'plus':line(16,4,16,28);line(4,16,28,16);
        c.drawPath(Path()..moveTo(16,4)..lineTo(16,28)..moveTo(4,16)..lineTo(28,16),p..strokeWidth=3.6);break;
      case 'home':path(const [Offset(2,14),Offset(16,2),Offset(30,14),Offset(27,14),Offset(27,29),Offset(19,29),Offset(19,20),Offset(13,20),Offset(13,29),Offset(5,29),Offset(5,14)],close:true,solid:true);break;
      case 'map':path(const [Offset(3,6),Offset(11,2),Offset(21,7),Offset(29,3),Offset(29,27),Offset(21,31),Offset(11,26),Offset(3,30)],close:true);line(11,2,11,26);line(21,7,21,31);break;
      case 'grid':for(final x in [3.0,19.0]) {for(final y in [3.0,19.0]) {c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,11,11),const Radius.circular(3)),fill);}}break;
      case 'navigation':path(const [Offset(2,14),Offset(29,3),Offset(19,30),Offset(14,19)],close:true,solid:true);line(14,19,29,3);break;
      case 'sun':c.drawCircle(const Offset(16,16),7,fill);for(var i=0;i<8;i++) {final a=i*math.pi/4; c.drawLine(Offset(16+11*math.cos(a),16+11*math.sin(a)),Offset(16+15*math.cos(a),16+15*math.sin(a)),p);}break;
      case 'bell':c.drawPath(Path()..moveTo(7,24)..lineTo(10,19)..lineTo(10,12)..cubicTo(10,4,22,4,22,12)..lineTo(22,19)..lineTo(25,24)..close(),fill);c.drawCircle(const Offset(16,27),2.5,fill);line(16,3,16,6);break;
    }
    c.restore();
  }
  @override
  bool shouldRepaint(_GarageIconPainter old)=>old.kind!=kind||old.color!=color;
}
