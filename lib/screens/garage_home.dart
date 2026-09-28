part of 'app_shell.dart';

// Shared garage colors and controls. Home artwork contains no baked-in UI.
const _amber = Color(0xFFFFBB4D);
const _ice = Color(0xFF22DCEF);
const _paper = Color(0xFFEDEFF2);
const _garageMonths = ['Январь','Февраль','Март','Апрель','Май','Июнь',
  'Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'];

// One scene coordinate system: 941 × 2038. Artwork is uniformly scaled and
// cropped only at the floor/outer edges. Hit targets use the identical transform.
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
    final padding = MediaQuery.paddingOf(context);
    final scale = math.max(size.width / 941, size.height / 2038);
    final offsetX = (size.width - 941 * scale) / 2;
    final book = data.book;
    final active = book?.active;
    final closed = (book?.shifts ?? <Map<String, dynamic>>[])
        .where((s) => s['end'] != null).toList()
      ..sort((a, b) => (b['end'] as String).compareTo(a['end'] as String));
    final last = closed.isEmpty ? null : closed.first;
    final current = active == null ? <Map<String, dynamic>>[]
        : book!.forShift(active['id'] as String);
    final trips = current.where((e) => e['kind'] == 'trip').length;
    double fuel(String type) => current.where((e) =>
        e['kind'] == 'fuel' && e['type'] == type)
        .fold<double>(0, (sum, e) => sum + (e['amount'] as num).toDouble());
    final paid = book == null ? 0 : book.records.where((e) =>
        e['kind'] == 'trip' && e['isPaid'] == true &&
        book.inMonth(book.recordDay(e).toIso8601String(), month)).length;
    void details(String metric) => _openMetricDetails(context, metric, month);
    void summary() => _testOpen(context, shiftId: (active ?? last)?['id'] as String?);
    void records(String page) => _testOpen(context, page: page,
        shiftId: active?['id'] as String?);
    final name = session.displayName.trim().isEmpty ? 'Водитель' : session.displayName;
    final initials = name.split(RegExp(r'\s+')).take(2).map((s) => s[0]).join();
    Widget place(double x, double y, double w, double h, Widget child) =>
        Positioned(left: x, top: y, width: w, height: h, child: child);
    final scene = SizedBox(width: 941, height: 2038, child: Stack(children: [
      Positioned.fill(child: RepaintBoundary(child: Image.asset(
        'assets/images/scenes/mill_home.png', fit: BoxFit.fill,
        filterQuality: FilterQuality.high, excludeFromSemantics: true))),
      // All display faces use the wall perspective, not independent offsets.
      _MillWallDisplay(points: const [Offset(64, 227), Offset(240, 298), Offset(240, 423), Offset(62, 363)],
        label: 'Платные\nнаправления', value: paid.toDouble(), unit: '',
        icon: Icons.toll_rounded, accent: _amber,
        onTap: () => _testOpen(context, page: 'Платные направления', month: month)),
      _MillWallDisplay(points: const [Offset(62, 438), Offset(240, 492), Offset(239, 595), Offset(61, 552)],
        label: 'Газ', value: data.gas, unit: ' л', icon: Icons.local_fire_department,
        accent: _amber, onTap: () => details('Газ')),
      _MillWallDisplay(points: const [Offset(61, 637), Offset(239, 672), Offset(239, 784), Offset(60, 755)],
        label: 'Бензин', value: data.petrol, unit: ' л', icon: Icons.local_gas_station,
        accent: const Color(0xFFFF6845), onTap: () => details('Бензин')),
      _MillWallDisplay(points: const [Offset(730, 329), Offset(878, 289), Offset(879, 438), Offset(729, 465)],
        label: 'Город', value: data.city * 1000, unit: ' кг', icon: Icons.location_city,
        accent: _amber, onTap: () => details('Город')),
      _MillWallDisplay(points: const [Offset(731, 510), Offset(879, 479), Offset(879, 635), Offset(730, 661)],
        label: 'Район', value: data.region * 1000, unit: ' кг', icon: Icons.location_on_outlined,
        accent: _ice, onTap: () => details('Район')),
      _MillWallDisplay(points: const [Offset(731, 709), Offset(878, 683), Offset(879, 801), Offset(731, 819)],
        label: 'Пробег', value: data.mileage, unit: ' км', icon: Icons.speed,
        accent: _amber, onTap: () => details('Пробег')),
      place(410, 917, 109, 108, _MillPress(
        label: active == null ? 'Начать смену' : 'Завершить смену',
        onTap: () => _openShiftAction(context),
        child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: Column(
          key: ValueKey(active != null), mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(active == null ? Icons.play_arrow_rounded : Icons.stop_rounded,
                color: _amber, size: 33), const SizedBox(height: 7),
            _millText(active == null ? 'НАЧАТЬ\nСМЕНУ' : 'ЗАВЕРШИТЬ\nСМЕНУ', 18,
                weight: FontWeight.w600),
          ])))),
      place(67, 1110, 162, 116, _MillStatus(icon: Icons.settings_outlined,
        title: active == null ? 'Смена закрыта' : 'Смена открыта', onTap: summary,
        child: _MillClock(start: active?['start'] as String?))),
      place(263, 1110, 171, 116, _MillStatus(icon: Icons.local_shipping_outlined,
        title: 'Рейсы', onTap: () => records('Рейсы'),
        child: _MillValue(value: trips.toDouble(), unit: _millTripUnit(trips), size: 25, color: _ice))),
      place(485, 1110, 193, 116, _MillStatus(icon: Icons.local_gas_station_outlined,
        title: 'Топливо', onTap: () => records('Топливо'),
        child: Column(children: [
          _MillValue(value: fuel('Газ'), prefix: 'Газ ', unit: ' л', size: 22, color: _ice),
          _MillValue(value: fuel('Бензин'), prefix: 'Бензин ', unit: ' л', size: 22, color: _ice),
        ]))),
      place(716, 1110, 156, 116, _MillStatus(icon: Icons.flag_outlined,
        title: 'Завершение', onTap: summary,
        child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child:
          _millText(active != null ? 'Ожидание' : last == null ? 'Нет итогов' :
            '${_fmt1(book!.mileage(last))} км\n${_fmt1(book.hours(last))} ч', 23,
            color: active == null && last != null ? _ice : const Color(0xFFAFB7BB),
            key: ValueKey('${active?["id"]}-${last?["id"]}-${last?["currentKm"]}-${last?["hoursWorked"]}'))))),
    ]));
    final top = math.max(padding.top / scale + 10, 83.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, statusBarBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1), duration: const Duration(milliseconds: 320),
        builder: (_, opacity, child) => Opacity(opacity: opacity, child: child),
        child: ClipRect(child: Stack(children: [
        Positioned(left: offsetX, top: 0, width: 941 * scale, height: 2038 * scale,
          child: FittedBox(fit: BoxFit.fill, child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 1, maxScaleFactor: 1, child: scene))),
        Positioned(left: 0, right: 0, top: top * scale, height: 87 * scale,
          child: Padding(padding: EdgeInsets.symmetric(horizontal: 27 * scale),
            child: Row(children: [
              Expanded(child: _MillPress(label: 'Профиль $name',
                onTap: () => _openHomeMenu(context, session), child: Row(children: [
                  Container(width: 64 * scale, height: 64 * scale,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x6605090E),
                      border: Border.all(color: _amber), boxShadow: const [BoxShadow(color: Color(0x44FFAA33), blurRadius: 9)]),
                    child: Center(child: _millText(initials, 25 * scale))),
                  SizedBox(width: 13 * scale), Expanded(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_millText(name, 24 * scale, align: TextAlign.left),
                      _millText('Тестовый режим', 17 * scale, color: const Color(0xFFBEC6CB), align: TextAlign.left)])),
                ]))),
              SizedBox(width: 12 * scale),
              SizedBox(width: 328 * scale, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 35 * scale, height: 54 * scale,
                  child: const CustomPaint(painter: _MillWheatMark())),
                SizedBox(width: 10 * scale), _millText('М Е Л Ь Н И Ц А', 24 * scale, weight: FontWeight.w600),
              ])),
              SizedBox(width: 198 * scale),
            ]))),
        Positioned(left: 230 * scale + offsetX, top: (top + 92) * scale,
          width: 480 * scale, height: 126 * scale,
          child: Column(children: [
            _millText('Заработано за месяц', 22 * scale),
            Expanded(child: Row(children: [
              Expanded(child: _MillPress(label: 'Предыдущий месяц', onTap: () => onMonthChanged(DateTime(month.year, month.month - 1)),
                child: const Icon(Icons.chevron_left, color: _paper))),
              Expanded(flex: 5, child: _MillPress(label: 'Зарплата за выбранный месяц', onTap: () => details('Зарплата'),
                child: _MillValue(value: data.salary, unit: ' ₸', size: 54 * scale, color: _amber))),
              Expanded(child: _MillPress(label: 'Следующий месяц', onTap: () => onMonthChanged(DateTime(month.year, month.month + 1)),
                child: const Icon(Icons.chevron_right, color: _paper))),
            ])),
            _MillPress(label: 'Выбрать месяц', onTap: () => _chooseMonth(context),
              child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child:
                _millText('${_garageMonths[month.month - 1]} ${month.year} ⌄', 23 * scale, key: ValueKey(month)))),
          ])),
        Positioned(left: 8, right: 8, bottom: padding.bottom + 3,
          child: _MillNavigation(onWork: () => onNavigate(1), onAdd: onQuickAdd,
            onInvoices: () => onNavigate(3), onMore: () => _openHomeMenu(context, session))),
      ]))),
    );
  }

  Future<void> _chooseMonth(BuildContext context) async {
    final selected = await showModalBottomSheet<DateTime>(context: context,
      backgroundColor: const Color(0xEE0B151D), builder: (c) => SafeArea(child: SizedBox(
        height: 300, child: GridView.count(crossAxisCount: 3, childAspectRatio: 2.2,
          padding: const EdgeInsets.all(16), children: List.generate(12, (i) => TextButton(
            onPressed: () => Navigator.pop(c, DateTime(month.year, i + 1)),
            child: Text(_garageMonths[i], style: TextStyle(color: i + 1 == month.month ? _amber : _paper))))))));
    if (selected != null) onMonthChanged(selected);
  }
}

class _MillWheatMark extends CustomPainter {
  const _MillWheatMark();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 35, size.height / 54);
    final paint = Paint()..color = _amber;
    canvas.drawPath(Path()..moveTo(10, 52)..quadraticBezierTo(20, 28, 25, 3),
      Paint()..color = _amber..style = PaintingStyle.stroke..strokeWidth = 1.7);
    for (var i = 0; i < 4; i++) {
      final y = 15.0 + i * 8;
      final x = 23.0 - i * 2.5;
      for (final side in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(x + side * 4, y);
        canvas.rotate(side * .65);
        canvas.drawOval(const Rect.fromLTWH(-2.8, -7, 5.6, 13), paint);
        canvas.restore();
      }
    }
    canvas.drawOval(const Rect.fromLTWH(23, 0, 5, 11), paint);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _MillWheatMark oldDelegate) => false;
}

String _millTripUnit(int n) => n % 100 >= 11 && n % 100 <= 14 ? ' рейсов'
    : n % 10 == 1 ? ' рейс' : n % 10 >= 2 && n % 10 <= 4 ? ' рейса' : ' рейсов';

Widget _millText(String text, double size, {Color color = _paper,
    FontWeight weight = FontWeight.w400, TextAlign align = TextAlign.center, Key? key}) =>
  Text(text, key: key, textAlign: align, maxLines: 2, overflow: TextOverflow.ellipsis,
    style: TextStyle(fontSize: size, height: 1.12, color: color, fontWeight: weight,
      shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 4)]));

class _MillValue extends StatelessWidget {
  final double value, size;
  final String unit, prefix;
  final Color color;
  const _MillValue({required this.value, this.unit = '', this.prefix = '', this.size = 40, this.color = _paper});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: value, end: value), duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic, builder: (_, v, __) => FittedBox(fit: BoxFit.scaleDown,
      child: _millText('$prefix${v == v.roundToDouble() ? _fmtInt(v) : _fmt1(v)}$unit', size,
        color: color, weight: FontWeight.w600)));
}

class _MillPress extends StatefulWidget {
  final String label;
  final Widget child;
  final VoidCallback onTap;
  const _MillPress({required this.label, required this.child, required this.onTap});
  @override
  State<_MillPress> createState() => _MillPressState();
}
class _MillPressState extends State<_MillPress> {
  bool pressed = false;
  void setPressed(bool v) { if (mounted) setState(() => pressed = v); }
  @override
  Widget build(BuildContext context) => Semantics(button: true, label: widget.label,
    child: GestureDetector(behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setPressed(true), onTapCancel: () => setPressed(false),
      onTapUp: (_) => setPressed(false), onTap: () { HapticFeedback.selectionClick(); widget.onTap(); },
      child: AnimatedScale(scale: pressed ? .965 : 1, duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(opacity: pressed ? .72 : 1,
          duration: const Duration(milliseconds: 100), child: widget.child))));
}

class _MillWallDisplay extends StatelessWidget {
  final List<Offset> points;
  final String label, unit;
  final double value;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  const _MillWallDisplay({required this.points, required this.label,
    required this.value, required this.unit, required this.icon, required this.accent, required this.onTap});
  @override
  Widget build(BuildContext context) {
    // Projective mapping of the rectangle onto the photographed metal face.
    final p0 = points[0], p1 = points[1], p2 = points[2], p3 = points[3];
    final dx1 = p1.dx - p2.dx, dx2 = p3.dx - p2.dx;
    final dy1 = p1.dy - p2.dy, dy2 = p3.dy - p2.dy;
    final dx3 = p0.dx - p1.dx + p2.dx - p3.dx;
    final dy3 = p0.dy - p1.dy + p2.dy - p3.dy;
    final determinant = dx1 * dy2 - dx2 * dy1;
    final g = (dx3 * dy2 - dx2 * dy3) / determinant;
    final h = (dx1 * dy3 - dx3 * dy1) / determinant;
    final matrix = Matrix4.identity()
      ..setEntry(0, 0, (p1.dx - p0.dx + g * p1.dx) / 200)
      ..setEntry(0, 1, (p3.dx - p0.dx + h * p3.dx) / 160)
      ..setEntry(0, 3, p0.dx)
      ..setEntry(1, 0, (p1.dy - p0.dy + g * p1.dy) / 200)
      ..setEntry(1, 1, (p3.dy - p0.dy + h * p3.dy) / 160)
      ..setEntry(1, 3, p0.dy)
      ..setEntry(3, 0, g / 200)..setEntry(3, 1, h / 160);
    return Positioned.fill(child: Align(alignment: Alignment.topLeft,
      child: Transform(transform: matrix, child: SizedBox(width: 200, height: 160,
        child: _MillPress(label: '$label ${_fmt1(value)}$unit', onTap: onTap,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(children: [Icon(icon, color: accent, size: 37), const SizedBox(width: 8),
                Expanded(child: _millText(label, 24, align: TextAlign.left))]),
              const SizedBox(height: 10),
              _MillValue(value: value, unit: unit, size: 43),
              const SizedBox(height: 11),
              Container(height: 2, decoration: BoxDecoration(color: accent.withValues(alpha: .7),
                boxShadow: [BoxShadow(color: accent.withValues(alpha: .35), blurRadius: 8)])),
            ])))))));
  }
}

class _MillStatus extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback onTap;
  const _MillStatus({required this.icon, required this.title, required this.child, required this.onTap});
  @override
  Widget build(BuildContext context) => _MillPress(label: title, onTap: onTap,
    child: Column(children: [Icon(icon, color: _amber, size: 32), const SizedBox(height: 5),
      _millText(title, 20), const SizedBox(height: 4), Expanded(child: Center(child: child))]));
}

class _MillClock extends StatefulWidget {
  final String? start;
  const _MillClock({this.start});
  @override
  State<_MillClock> createState() => _MillClockState();
}
class _MillClockState extends State<_MillClock> {
  Timer? timer;
  @override
  void initState() { super.initState(); syncTimer(); }
  @override
  void didUpdateWidget(covariant _MillClock oldWidget) {
    super.didUpdateWidget(oldWidget); if (oldWidget.start != widget.start) syncTimer();
  }
  void syncTimer() {
    timer?.cancel();
    if (widget.start != null) timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && TickerMode.of(context)) setState(() {});
    });
  }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (widget.start == null) return _millText('—', 25, color: const Color(0xFFAFB7BB));
    final seconds = math.max(0, DateTime.now().difference(DateTime.parse(widget.start!)).inSeconds);
    String pad(int n) => n.toString().padLeft(2, '0');
    return _millText('${pad(seconds ~/ 3600)}:${pad(seconds ~/ 60 % 60)}:${pad(seconds % 60)}', 25, color: _ice);
  }
}

class _MillNavigation extends StatelessWidget {
  final VoidCallback onWork, onAdd, onInvoices, onMore;
  const _MillNavigation({required this.onWork, required this.onAdd, required this.onInvoices, required this.onMore});
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(25),
    child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: Container(height: 72, decoration: BoxDecoration(
        color: const Color(0x36070D12), borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0x80EFAF5D), width: .7)),
        child: Row(children: [
          item('Главная', Icons.home_outlined, () {}, active: true),
          item('Работа', Icons.local_shipping_outlined, onWork),
          Expanded(child: _MillPress(label: 'Добавить рейс или топливо', onTap: onAdd,
            child: Center(child: Container(width: 54, height: 54,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x38291708),
                border: Border.all(color: _amber, width: 1.5),
                boxShadow: const [BoxShadow(color: Color(0x44FFAA22), blurRadius: 12)]),
              child: const Icon(Icons.add, color: _amber, size: 37))))),
          item('Накладные', Icons.receipt_long_outlined, onInvoices),
          item('Ещё', Icons.grid_view_outlined, onMore),
        ]))));
  Widget item(String title, IconData icon, VoidCallback tap, {bool active = false}) => Expanded(
    child: _MillPress(label: title, onTap: tap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 25, color: active ? _amber : _paper,
        shadows: active ? const [Shadow(color: Color(0x88FFAA22), blurRadius: 12)] : null),
      const SizedBox(height: 5), FittedBox(fit: BoxFit.scaleDown,
        child: _millText(title, 10, color: active ? _amber : _paper)),
    ])));
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
  final VoidCallback onHistory,onDirections,onDocuments,onStats;
  const _GarageRail({required this.onHistory,required this.onDirections,required this.onDocuments,required this.onStats});
  @override
  Widget build(BuildContext context) {
    final items=[(Icons.history,'История',onHistory),(Icons.bar_chart_outlined,'Статистика',onStats),
      (Icons.alt_route,'Направления',onDirections),(Icons.folder_outlined,'Документы',onDocuments)];
    return ClipRRect(borderRadius:BorderRadius.circular(22),child:BackdropFilter(filter:ImageFilter.blur(sigmaX:2.5,sigmaY:2.5),
      child:Container(decoration:BoxDecoration(color:const Color(0x40060D12),borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0x558C969C))),
        padding:const EdgeInsets.symmetric(vertical:18),child:Column(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
          for(final item in items)_GarageTap(label:item.$2,onTap:item.$3,child:SizedBox(width:102,height:132,
            child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(item.$1,color:const Color(0xFFBBCAD3),size:40),
              const SizedBox(height:16),FittedBox(fit:BoxFit.scaleDown,child:_garageText(item.$2,17))])))]))));
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
  final String login;
  final VoidCallback onOpen;
  const _GarageOil({required this.login,required this.onOpen});
  @override
  State<_GarageOil> createState()=>_GarageOilState();
}
class _GarageOilState extends State<_GarageOil> {
  int? remaining;
  @override
  void initState(){super.initState();_homeDataRevision.addListener(_load);_load();}
  @override
  void dispose(){_homeDataRevision.removeListener(_load);super.dispose();}
  Future<void> _load() async {
    try {final book=await MaintenanceRepository(widget.login).load();
      final next=book.latest('oil')?.nextKm;
      if(mounted)setState(()=>remaining=next==null?null:next-book.odometer);
    }catch(_){if(mounted)setState(()=>remaining=null);}
  }
  @override
  Widget build(BuildContext context)=>_GarageTap(label:'До замены масла',onTap:widget.onOpen,
    child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
      const _GarageIcon('oil',color:_amber,size:33),const SizedBox(width:14),
      _garageText('До замены масла  ·  ',20),
      Flexible(child:FittedBox(fit:BoxFit.scaleDown,child:Text(
        remaining==null?'—':'${_fmtInt(remaining!.toDouble())} км',
        style:TextStyle(color:remaining!=null&&remaining!<0?Colors.redAccent:_amber,fontSize:23))))]));
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
    final items=[('homeOutline','Главная',(){}),('truck','Работа',onWork),('plus','Добавить',onAdd),
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
