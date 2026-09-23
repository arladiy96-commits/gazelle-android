part of 'app_shell.dart';

// Coordinates describe the screen inside the reference phone, not its bezel.
// One width-based scale keeps typography, strokes and artwork in proportion.
const _amber = Color(0xFFFF9C38);
const _ice = Color(0xFF26DCFF);
const _paper = Color(0xFFEAEAF2);

class _ReferenceHomeDashboard extends StatelessWidget {
  final AppSession session;
  final _HomeMonthData data;
  final Size size;
  final ValueChanged<int> onNavigate;
  final VoidCallback onQuickAdd;

  const _ReferenceHomeDashboard({required this.session, required this.data,
    required this.size, required this.onNavigate, required this.onQuickAdd});

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final scale = size.width / 840;
    final height = math.max(1360.0, (size.height - safeBottom) / scale);
    final extra = height - 1360;
    final sceneScale = (800 + extra) / 800;
    final menu = () => _openHomeMenu(context, session);
    Widget place(double x, double y, double w, double h, Widget child) =>
      Positioned(left: x, top: y, width: w, height: h, child: child);
    Widget action(String label, VoidCallback tap, Widget child) =>
      Semantics(button: true, label: label, child: GestureDetector(
        behavior: HitTestBehavior.opaque, onTap: () {
          HapticFeedback.selectionClick(); tap();
        }, child: child));

    final canvas = SizedBox(width: 840, height: height, child: Stack(children: [
      Positioned.fill(child: Container(color: const Color(0xFF02070A))),
      Positioned(left: 0, top: -50, width: 840, height: 1120 + extra,
        child: Image.asset('assets/images/garage_scene.png', fit: BoxFit.fill,
          filterQuality: FilterQuality.high)),
      Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration:
        BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter,
          end: Alignment.bottomCenter, stops: const [0, .15, .55, .79, 1],
          colors: [Colors.black.withValues(alpha: .27), Colors.transparent,
            Colors.transparent, const Color(0xDC02070A), const Color(0xFF02070A)]))))),
      // Bent leaders terminate on the truck; they never run through labels.
      Positioned(left: 0, top: 0, width: 840, height: 800 + extra,
        child: const IgnorePointer(child: CustomPaint(painter: _GarageLeaders()))),
      place(36, 18, 216, 76, action('Профиль', menu, Row(children: [
        Container(width: 70, height: 70, decoration: BoxDecoration(
          shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE6D7BC)),
          gradient: const LinearGradient(colors: [Color(0xFF14202B), Color(0xFF402615)])),
          child: const Icon(Icons.person_outline_rounded, color: _paper, size: 40)),
        const SizedBox(width: 18), Expanded(child: Column(
          mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
          children: [_garageText(session.displayName, 22, weight: FontWeight.w600),
            _garageText(session.role.title, 16, color: const Color(0xFFCED0D7))]))]))),
      place(270, 26, 215, 64, Transform.rotate(angle: -.16,
        child: const Text('Движение\nэто жизнь', textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic,
            color: _paper, fontSize: 27, height: .95, fontWeight: FontWeight.w300)))),
      place(575, 25, 154, 66, Row(children: [
        const _GarageIcon('sun', color: Color(0xFFFFC438), size: 42),
        const SizedBox(width: 10), Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            _garageText('-12°', 28, weight: FontWeight.w600),
            _garageText('Петропавловск', 13)]))])),
      place(753, 26, 58, 58, action('Уведомления', () {
        showModalBottomSheet<void>(context: context, backgroundColor: const Color(0xFF10181E),
          builder: (_) => const SafeArea(child: Padding(padding: EdgeInsets.all(28),
            child: Text('Уведомления ещё не подключены', style: TextStyle(color: _paper)))));
      }, _GarageGlass(radius: 40, child: const Center(
        child: _GarageIcon('bell', color: Color(0xFFFFD9A4), size: 28))))),
      place(8, 150, 94, 656 * sceneScale, _GarageRail(
        onShift: () => onNavigate(1), onTrips: () => onNavigate(1),
        onFuel: onQuickAdd, onExpenses: onQuickAdd,
        onStats: () => onNavigate(4), onInvoices: () => onNavigate(3), onMore: menu)),
      place(260, 164, 312, 78, action('Открыть текущую смену', () => onNavigate(1),
        const _GarageShift())),
      place(660, 174, 151, 118, Transform.rotate(angle: -.1,
        child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(7),
          color: const Color(0x550F0904), border: Border.all(color: _amber, width: 1.8),
          boxShadow: const [BoxShadow(color: Color(0x66FF730C), blurRadius: 14)]),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('ГАЗЕЛЬ', style: TextStyle(color: Color(0xFFFFE7C9),
              fontStyle: FontStyle.italic, fontSize: 28, fontWeight: FontWeight.w700,
              letterSpacing: 3, shadows: [Shadow(color: _amber, blurRadius: 10)])),
            const SizedBox(height: 10), _garageText('БОЛЬШЕ\nЧЕМ РАБОТА', 15,
              align: TextAlign.center, color: const Color(0xFFE9D2BE))])))),
      place(112, 274 * sceneScale, 205, 100, _GarageHud(kind: 'flame',
        label: 'Газ', value: '${_fmt1(data.gas)} л', color: _ice, onTap: onQuickAdd)),
      place(112, 486 * sceneScale, 205, 100, _GarageHud(kind: 'fuel',
        label: 'Бензин', value: '${_fmt1(data.petrol)} л',
        color: const Color(0xFFFF4E53), onTap: onQuickAdd)),
      place(610, 300 * sceneScale, 223, 94, _GarageHud(kind: 'box',
        label: 'Тоннаж', value: '${_fmt1(data.tonnage)} т', color: _amber,
        onTap: () => onNavigate(4))),
      place(661, 414 * sceneScale, 172, 94, _GarageHud(kind: 'route',
        label: 'Рейсы', value: '${data.trips}', color: const Color(0xFFD58AFF),
        onTap: () => onNavigate(1))),
      place(668, 599 * sceneScale, 165, 90, _GarageHud(kind: 'road',
        label: 'Пробег', value: '${_fmtInt(data.mileage)} км', color: const Color(0xFFFFBA59),
        compact: true, onTap: () => onNavigate(4))),
      place(22, 825 + extra, 296, 190, _GarageSalary(data: data,
        onTap: () => onNavigate(4))),
      place(337, 798 + extra, 184, 200, action('Завершить смену: открыть управление сменой',
        () => onNavigate(1), const _GarageEndShift())),
      place(538, 825 + extra, 284, 182, const _GarageQuote()),
      place(20, 1035 + extra, 805, 136, _GarageTrip(onTap: () => onNavigate(1))),
      place(10, 1190 + extra, 820, 135, _GarageNavigation(
        onWork: () => onNavigate(1), onAdd: onQuickAdd,
        onInvoices: () => onNavigate(3), onMore: menu)),
      place(130, 1330 + extra, 580, 25, const Text('С В О Й  П У Т Ь .   С В О И  П Р А В И Л А .',
        textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFD1D2D5), fontSize: 12))),
    ]));
    return ColoredBox(color: const Color(0xFF02070A), child: SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(padding: EdgeInsets.only(bottom: safeBottom),
        child: SizedBox(width: size.width, height: height * scale,
          child: FittedBox(fit: BoxFit.fill, alignment: Alignment.topCenter,
            child: MediaQuery.withClampedTextScaling(minScaleFactor: 1, maxScaleFactor: 1,
              child: canvas))))));
  }
}

Widget _garageText(String value, double size, {Color color = _paper,
  FontWeight weight = FontWeight.w400, TextAlign align = TextAlign.start}) =>
  Text(value, textAlign: align, maxLines: 2, overflow: TextOverflow.ellipsis,
    style: TextStyle(color: color, fontSize: size, height: 1.25, fontWeight: weight));

class _GarageGlass extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color edge;
  const _GarageGlass({required this.child, this.radius = 22,
    this.edge = const Color(0xFF53616C)});
  @override
  Widget build(BuildContext context) => Container(decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(radius), border: Border.all(color: edge.withValues(alpha: .6)),
    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xED1D252D), Color(0xEF080E13), Color(0xDD0A161D)])),
    child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: child));
}

class _GarageRail extends StatelessWidget {
  final VoidCallback onShift, onTrips, onFuel, onExpenses, onStats, onInvoices, onMore;
  const _GarageRail({required this.onShift, required this.onTrips, required this.onFuel,
    required this.onExpenses, required this.onStats, required this.onInvoices, required this.onMore});
  @override
  Widget build(BuildContext context) {
    final items = [('shift','Смена',onShift), ('truck','Рейсы',onTrips),
      ('fuel','Топливо',onFuel), ('expense','Расходы',onExpenses),
      ('chart','Статистика',onStats), ('invoice','Накладные',onInvoices), ('more','Ещё',onMore)];
    return _GarageGlass(radius: 27, edge: _amber, child: Column(children: [
      for (var i = 0; i < items.length; i++) Expanded(child: Semantics(
        button: true, label: items[i].$2, child: GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: items[i].$3,
          child: Container(margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: i == 0 ? BoxDecoration(borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _amber, width: 1.5),
              gradient: const RadialGradient(colors: [Color(0xFF4A2D11), Color(0xFF100C08)]),
              boxShadow: const [BoxShadow(color: Color(0x88FF791A), blurRadius: 16)]) : null,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              _GarageIcon(items[i].$1, color: i == 0 ? const Color(0xFFFFCA67) : const Color(0xFFBABCD5), size: 34),
              const SizedBox(height: 9), _garageText(items[i].$2, 15,
                color: i == 0 ? const Color(0xFFFFD875) : _paper)])))))
    ]));
  }
}

class _GarageShift extends StatelessWidget {
  const _GarageShift();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFF8DE6E0)),
      gradient: const LinearGradient(colors: [Color(0xD50A4347), Color(0xEF021E24)]),
      boxShadow: const [BoxShadow(color: Color(0x5522CECA), blurRadius: 20)]),
    child: Row(children: [Container(width: 44, height: 44,
      decoration: const BoxDecoration(shape: BoxShape.circle,
        gradient: RadialGradient(colors: [Color(0xFF00DEC9), Color(0xFF004749)])),
      child: const Center(child: Icon(Icons.circle, color: Color(0xFF04E2C8), size: 18))),
      const SizedBox(width: 12), Expanded(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
        children: [_garageText('Смена открыта', 19, weight: FontWeight.w600),
          _garageText('02:14:26', 30, color: _ice, weight: FontWeight.w600)])),
      Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle,
        color: const Color(0xAA071015), border: Border.all(color: const Color(0xFF70CFCC))),
        child: const Icon(Icons.pause_rounded, color: _paper, size: 30))]));
}

class _GarageHud extends StatelessWidget {
  final String kind, label, value;
  final Color color;
  final VoidCallback onTap;
  final bool compact;
  const _GarageHud({required this.kind, required this.label, required this.value,
    required this.color, required this.onTap, this.compact = false});
  @override
  Widget build(BuildContext context) => Semantics(button: true, label: '$label: $value',
    child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap,
      child: Row(children: [SizedBox(width: compact ? 68 : 78, height: compact ? 82 : 94,
        child: CustomPaint(painter: _GarageRing(color), child: Center(
          child: _GarageIcon(kind, color: kind == 'box' ? _paper : color, size: compact ? 39 : 43)))),
        const SizedBox(width: 10), Expanded(child: Column(
          mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
          children: [_garageText(label, compact ? 15 : 17),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
              child: _garageText(value, compact ? 22 : 28, weight: FontWeight.w600)),
            _garageText('за месяц', 15)]))])));
}

class _GarageRing extends CustomPainter {
  final Color color;
  const _GarageRing(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    canvas.drawOval(oval, Paint()..shader = RadialGradient(colors: [
      const Color(0xE60A1119), const Color(0xDD080C12), color.withValues(alpha: .16)]).createShader(oval));
    for (final arc in [(0.10, 1.2), (1.46, 1.36), (3.02, 1.28), (4.53, .67)]) {
      canvas.drawArc(oval, arc.$1, arc.$2, false, Paint()..style = PaintingStyle.stroke
        ..strokeWidth = 6..color = color.withValues(alpha: .45)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
      canvas.drawArc(oval, arc.$1, arc.$2, false, Paint()..style = PaintingStyle.stroke
        ..strokeWidth = 2.5..color = color);
    }
  }
  @override
  bool shouldRepaint(_GarageRing old) => old.color != color;
}

class _GarageLeaders extends CustomPainter {
  const _GarageLeaders();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save(); canvas.scale(size.width / 840, size.height / 800);
    void line(Color color, List<Offset> points) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) { path.lineTo(p.dx, p.dy); }
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: .7)
        ..style = PaintingStyle.stroke..strokeWidth = 6..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.7);
      canvas.drawCircle(points.last, 7, Paint()..color = color..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(points.last, 2.6, Paint()..color = Colors.white);
    }
    line(_ice, const [Offset(146,371),Offset(188,371),Offset(257,420)]);
    line(const Color(0xFFFF5A42), const [Offset(145,581),Offset(192,581),Offset(243,615)]);
    line(_amber, const [Offset(612,353),Offset(583,353),Offset(548,382)]);
    line(const Color(0xFFF18BCB), const [Offset(663,462),Offset(645,462),Offset(618,482)]);
    canvas.restore();
  }
  @override
  bool shouldRepaint(_GarageLeaders old) => false;
}

class _GarageSalary extends StatelessWidget {
  final _HomeMonthData data; final VoidCallback onTap;
  const _GarageSalary({required this.data, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: _GarageGlass(edge: const Color(0xFF8A6A48), child: Padding(
      padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [_garageText('Заработано за месяц', 17),
          _garageText('${_fmtInt(data.salary)} ₸', 34, weight: FontWeight.w600),
          const SizedBox(height: 8), const Expanded(child: CustomPaint(
            size: Size(double.infinity, 42), painter: _GarageBars())),
          const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: (data.salary / 40000).clamp(0.0, 1.0),
              minHeight: 9, color: _amber, backgroundColor: const Color(0xFF242B32))),
          const SizedBox(height: 8), Row(children: [Expanded(child: _garageText('Цель: 40 000 ₸', 14)),
            _garageText('${(data.salary / 40000 * 100).round()}%', 14)])]))));
}

class _GarageBars extends CustomPainter {
  const _GarageBars();
  @override
  void paint(Canvas canvas, Size size) {
    const values = [.24,.54,.45,.37,.48,.68,.94,.53,.37,.62,1,.80,.40];
    final width = size.width / values.length;
    for (var i=0; i<values.length; i++) {
      final rect = Rect.fromLTWH(i*width+5, size.height*(1-values[i]), 6, size.height*values[i]);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [i<7 ? const Color(0xFFFFC780) : const Color(0xFF82949F),
            i<7 ? const Color(0xFFB4550C) : const Color(0xFF151E27)]).createShader(rect));
    }
  }
  @override
  bool shouldRepaint(_GarageBars old) => false;
}

class _GarageEndShift extends StatelessWidget {
  const _GarageEndShift();
  @override
  Widget build(BuildContext context) => Center(child: Container(width: 174, height: 174,
    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFE6BB), width: 2.5),
      gradient: const RadialGradient(colors: [Color(0xFF231004), Color(0xFF080807), Color(0xFF683000)], stops: [0,.83,1]),
      boxShadow: const [BoxShadow(color: Color(0xFFFF780E), blurRadius: 12, spreadRadius: 2),
        BoxShadow(color: Color(0x88FF710A), blurRadius: 34, spreadRadius: 9)]),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 26, height: 27, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFFFE4AF)),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFFE6A7), Color(0xFFFF9A20)]),
        boxShadow: const [BoxShadow(color: Color(0x99FF7400), blurRadius: 20)])),
      const SizedBox(height: 21), _garageText('ЗАВЕРШИТЬ\nСМЕНУ', 18, align: TextAlign.center)])));
}

class _GarageQuote extends StatelessWidget {
  const _GarageQuote();
  @override
  Widget build(BuildContext context) => _GarageGlass(child: Stack(children: [
    const Positioned.fill(child: CustomPaint(painter: _GarageRoadArt())),
    Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
      colors: [const Color(0xFF0D1821), const Color(0xFF0D1821).withValues(alpha: .1)])))),
    Padding(padding: const EdgeInsets.all(26), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [const Text('“', style: TextStyle(color: _amber, fontSize: 52, height: .7)),
        const SizedBox(height: 12), _garageText('Дороги не спрашивают,', 16),
        _garageText('куда ты идёшь.', 16), _garageText('Они просто ведут.', 16)]))]));
}

class _GarageTrip extends StatelessWidget {
  final VoidCallback onTap;
  const _GarageTrip({required this.onTap});
  @override
  Widget build(BuildContext context) => _GarageGlass(child: Padding(padding: const EdgeInsets.all(16),
    child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(14),
      child: const SizedBox(width: 108, height: 104, child: CustomPaint(painter: _GarageRoadArt()))),
      const SizedBox(width: 22), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, children: [_garageText('Текущий рейс', 16),
          const SizedBox(height: 6), FittedBox(fit: BoxFit.scaleDown, child:
            _garageText('Петропавловск  →  Кокшетау', 23, weight: FontWeight.w600)),
          const SizedBox(height: 9), Row(children: [const _GarageIcon('pin', size: 22),
            const SizedBox(width: 7), _garageText('124 км  ·  1,8 т  ·  ≈2 ч 10 мин', 16)])])),
      const SizedBox(width: 16), GestureDetector(onTap: onTap, child: Container(
        width: 198, height: 70, decoration: BoxDecoration(borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _amber, width: 1.4), color: const Color(0xBB090D10),
          boxShadow: const [BoxShadow(color: Color(0x55FF8318), blurRadius: 16)]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const _GarageIcon('navigation', color: _amber, size: 35), const SizedBox(width: 14),
          _garageText('Навигация', 18)]))),
      const SizedBox(width: 14), GestureDetector(onTap: onTap, child: const SizedBox(width: 38, height: 72,
        child: _GarageGlass(radius: 15, child: Center(child: RotatedBox(quarterTurns: 1,
          child: _GarageIcon('more', size: 28))))))])));
}

class _GarageNavigation extends StatelessWidget {
  final VoidCallback onWork, onAdd, onInvoices, onMore;
  const _GarageNavigation({required this.onWork, required this.onAdd,
    required this.onInvoices, required this.onMore});
  @override
  Widget build(BuildContext context) {
    final items = [('home','Главная', () {}), ('map','Карта',onWork),
      ('plus','Добавить',onAdd), ('invoice','Накладные',onInvoices), ('grid','Ещё',onMore)];
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(child: _GarageGlass(radius: 36, child: Row(children: [
        for (var i=0; i<5; i++) Expanded(child: Semantics(button: true, label: items[i].$2,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: items[i].$3,
            child: Container(decoration: i==0 ? const BoxDecoration(
              gradient: RadialGradient(colors: [Color(0x885B330D), Colors.transparent], radius: 1)) : null,
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                if(i!=2) _GarageIcon(items[i].$1, color: i==0 ? const Color(0xFFFFC260) : _paper, size: 37),
                const SizedBox(height: 13), _garageText(items[i].$2, 18,
                  color: i==0 ? const Color(0xFFFFD66B) : _paper), const SizedBox(height: 20)])))))
      ]))),
      Positioned(left: 360, top: -14, width: 100, height: 100,
        child: Semantics(button: true, label: 'Добавить', child: GestureDetector(onTap: onAdd,
          child: Container(decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: const RadialGradient(colors: [Color(0xFF352112), Color(0xFF080B0C)]),
            border: Border.all(color: const Color(0xFFFFD3A0), width: 2.5),
            boxShadow: const [BoxShadow(color: Color(0xCCFF7920), blurRadius: 14)]),
            child: const Center(child: _GarageIcon('plus', color: _amber, size: 44)))))),
      Positioned(left: 42, bottom: 1, width: 93, child: Container(height: 3,
        decoration: const BoxDecoration(color: Color(0xFFFFD27A),
          boxShadow: [BoxShadow(color: Color(0xFFFF7800), blurRadius: 10, spreadRadius: 3)])))
    ]);
  }
}

// Small self-contained vector illustration; no remote image requests at launch.
class _GarageRoadArt extends CustomPainter {
  const _GarageRoadArt();
  @override
  void paint(Canvas c, Size s) {
    c.save(); c.clipRect(Offset.zero & s); c.scale(s.width/200, s.height/180);
    c.drawRect(const Rect.fromLTWH(0,0,200,180), Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF385B76), Color(0xFFE2A169), Color(0xFF122536)], stops: [0,.52,1])
      .createShader(const Rect.fromLTWH(0,0,200,180)));
    c.drawPath(Path()..moveTo(0,105)..lineTo(27,61)..lineTo(45,84)..lineTo(68,46)
      ..lineTo(104,111)..lineTo(145,69)..lineTo(167,91)..lineTo(200,37)..lineTo(200,180)..lineTo(0,180)..close(),
      Paint()..color = const Color(0xFF1B3549));
    c.drawPath(Path()..moveTo(0,125)..lineTo(28,94)..lineTo(43,121)..lineTo(70,86)
      ..lineTo(105,124)..lineTo(155,99)..lineTo(200,82)..lineTo(200,180)..lineTo(0,180)..close(),
      Paint()..color = const Color(0xFF101D27));
    final road = Path()..moveTo(91,112)..cubicTo(148,131,54,135,154,180)
      ..lineTo(43,180)..cubicTo(18,138,139,129,91,112)..close();
    c.drawPath(road, Paint()..color = const Color(0xFF566068));
    c.drawPath(Path()..moveTo(92,114)..cubicTo(142,131,31,139,75,180),
      Paint()..style=PaintingStyle.stroke..strokeWidth=1.8..color=const Color(0xFFE7B475));
    c.drawPath(Path()..moveTo(93,114)..cubicTo(155,134,63,136,147,180),
      Paint()..style=PaintingStyle.stroke..strokeWidth=1.2..color=const Color(0xFFC4B9A2));
    c.drawPath(Path()..moveTo(94,141)..lineTo(91,149)..moveTo(94,160)..lineTo(105,178),
      Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=const Color(0xFFFFD99A));
    c.restore();
  }
  @override
  bool shouldRepaint(_GarageRoadArt old) => false;
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
        for(var i=0;i<8;i++) {final a=i*math.pi/4; c.drawLine(Offset(16+12*math.cos(a),16+12*math.sin(a)),Offset(16+14*math.cos(a),16+14*math.sin(a)),p);}
        final pts=List.generate(8,(i)=>Offset(16+13*math.cos(i*math.pi/4),16+13*math.sin(i*math.pi/4)));
        path(pts,close:true);c.drawCircle(const Offset(16,16),4,p);break;
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
