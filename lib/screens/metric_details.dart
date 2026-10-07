part of 'app_shell.dart';

Future<void> _openMetricDetails(
  BuildContext context,
  String metric,
  DateTime month,
) async {
  await Navigator.of(context).push<void>(
    _SceneRoute(
      builder: (_) => metric == 'Зарплата'
          ? _SalaryDashboard(month: month)
          : (metric == 'Газ' || metric == 'Бензин')
          ? _GasDashboard(month: month, petrol: metric == 'Бензин')
          : metric == 'Город'
          ? _DistrictDashboard(month: month, city: true)
          : metric == 'Район'
          ? _DistrictDashboard(month: month)
          : metric == 'Пробег'
          ? _MileageReference(month: month)
          : _MetricDetails(metric: metric, month: month),
    ),
  );
}

String _detailDate(DateTime d) =>
    '${d.day} ${const ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'][d.month - 1]}';
String _detailTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
Text _dt(
  String s, {
  double size = 13,
  Color color = _paper,
  FontWeight weight = FontWeight.w400,
}) => Text(
  s,
  style: TextStyle(
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: 1.25,
  ),
);

class _DetailGlass extends StatelessWidget {
  final Widget child;
  final bool accent;
  final EdgeInsets padding;
  const _DetailGlass({
    required this.child,
    this.accent = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: accent ? const Color(0xBFFFBE5C) : const Color(0xB57899A9),
      ),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xB316252D), Color(0xC7071219)],
      ),
      boxShadow: accent
          ? const [BoxShadow(color: Color(0x14FFB23C), blurRadius: 10)]
          : null,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class _DetailFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final ScrollController? controller;
  final _Scene? scene;
  final bool embedded, showHero;
  final Widget? action;
  const _DetailFrame({
    required this.title,
    required this.children,
    this.controller,
    this.scene,
    this.embedded = false,
    this.showHero = true,
    this.action,
  });
  @override
  Widget build(BuildContext context) {
    final resolved = scene ?? _sceneFor(title);
    final body = Stack(
      children: [
        Positioned.fill(child: _SceneBackdrop(scene: resolved)),
        SafeArea(
          top: !embedded,
          bottom: !embedded,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: embedded
                          ? null
                          : IconButton(
                              tooltip: 'Назад',
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(
                                Icons.chevron_left,
                                color: _amber,
                              ),
                            ),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _paper,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child:
                          action ??
                          (embedded
                              ? null
                              : IconButton(
                                  tooltip: 'На главную',
                                  onPressed: () =>
                                      Navigator.of(context)
                                          .popUntil((r) => r.isFirst),
                                  icon: const Icon(
                                    Icons.close,
                                    color: _paper,
                                    size: 21,
                                  ),
                                )),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _SceneReveal(
                  child: ListView(
                    key: PageStorageKey('scene-$title'),
                    controller: controller,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      if (showHero) _SceneSpace(scene: resolved),
                      ...children,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    return embedded
        ? body
        : Scaffold(backgroundColor: const Color(0xFF030B10), body: body);
  }
}

Widget _detailButton(
  String label,
  VoidCallback action, {
  IconData icon = Icons.chevron_right,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: OutlinedButton.icon(
    onPressed: action,
    icon: Icon(icon, size: 18),
    label: Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: _amber,
      backgroundColor: const Color(0xC0081319),
      side: const BorderSide(color: Color(0xBFFFBE5C)),
      minimumSize: const Size.fromHeight(44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
);
Widget _detailRow(
  String label,
  String value, {
  VoidCallback? onTap,
  String? subtitle,
  Color? color,
}) => InkWell(
  onTap: onTap,
  borderRadius: BorderRadius.circular(12),
  child: Container(
    constraints: const BoxConstraints(minHeight: 44),
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dt(label, color: color ?? _paper),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                _dt(subtitle, size: 12, color: const Color(0xFFADC0CC)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        _dt(value, weight: FontWeight.w500),
        if (onTap != null) ...[
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: _paper, size: 18),
        ],
      ],
    ),
  ),
);
List<Widget> _separated(List<Widget> rows) => [
  for (var i = 0; i < rows.length; i++) ...[
    if (i > 0) const Divider(height: 1, color: Color(0x803E505B)),
    rows[i],
  ],
];

// Барабанный механический одометр. Фото даёт металлическую окантовку,
// Painter рисует только сменяющиеся колёса внутри окна.
class _MileageDrumPainter extends CustomPainter {
  final String reading;
  const _MileageDrumPainter(this.reading);
  TextPainter _glyph(
    String text,
    double size,
    Color color, {
    bool bold = true,
  }) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: color,
        shadows: const [Shadow(color: Color(0xAF000000), blurRadius: 2)],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 190, size.height / 74);
    final window = RRect.fromRectAndRadius(
      const Rect.fromLTWH(1, 3, 188, 68),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      window,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF060403), Color(0xFF3A1B0C), Color(0xFF170A05)],
        ).createShader(const Rect.fromLTWH(0, 0, 190, 74)),
    );
    canvas.save();
    canvas.clipRRect(window);

    final clean = reading.replaceAll(RegExp(r'[^0-9]'), '');
    final digits = clean.isEmpty
        ? '------'
        : (clean.length > 6
              ? clean.substring(clean.length - 6)
              : clean.padLeft(6, '0'));

    const left = 7.0;
    const slotWidth = 29.4;
    for (var i = 0; i < 6; i++) {
      final x = left + i * slotWidth;
      final isLast = i == 5;
      canvas.drawRect(
        Rect.fromLTWH(x, 4, slotWidth - 1.2, 66),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLast
                ? const [
                    Color(0xFF4B1606),
                    Color(0xFF7C3010),
                    Color(0xFF240A04),
                  ]
                : const [
                    Color(0xFF201009),
                    Color(0xFF663414),
                    Color(0xFF281105),
                  ],
          ).createShader(Rect.fromLTWH(x, 0, slotWidth, 74)),
      );
      canvas.drawLine(
        Offset(x + slotWidth - 1.4, 5),
        Offset(x + slotWidth - 1.4, 69),
        Paint()
          ..color = const Color(0xAF050402)
          ..strokeWidth = 1.7,
      );
      final current = digits[i];
      if (current == '-') {
        final dash = _glyph('–', 32, const Color(0xFFFFC97B));
        dash.paint(canvas, Offset(x + (slotWidth - dash.width) / 2, 17));
      } else {
        final n = int.parse(current);
        for (final pair in [
          (((n + 9) % 10).toString(), -25.0, const Color(0x668C683E)),
          (current, 13.0, const Color(0xFFFFD79A)),
          (((n + 1) % 10).toString(), 52.0, const Color(0x886C4622)),
        ]) {
          final glyph = _glyph(pair.$1, 38, pair.$3);
          glyph.paint(
            canvas,
            Offset(x + (slotWidth - glyph.width) / 2, pair.$2),
          );
        }
      }
    }

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 190, 74),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, .16, .35, .73, .95, 1],
          colors: [
            Color(0xE5000000),
            Color(0x44000000),
            Color(0x00000000),
            Color(0x00000000),
            Color(0x66000000),
            Color(0xD9000000),
          ],
        ).createShader(const Rect.fromLTWH(0, 0, 190, 74)),
    );
    canvas.drawLine(
      const Offset(4, 11),
      const Offset(185, 11),
      Paint()
        ..color = const Color(0x55FFD18C)
        ..strokeWidth = 1.1,
    );
    canvas.restore();
    canvas.drawRRect(
      window,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xAA49290E),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MileageDrumPainter old) =>
      old.reading != reading;
}

// Геометрия строится только из сохранённых координат. Фоновая сетка
// декоративная, она НЕ является картой дорог или навигацией.
class _MileageRecordedTrackPainter extends CustomPainter {
  final List<Map<String, dynamic>> points;
  const _MileageRecordedTrackPainter(this.points);

  @override
  void paint(Canvas canvas, Size s) {
    final grid = Paint()
      ..color = const Color(0x2D63808B)
      ..strokeWidth = .7;
    for (var x = 0.0; x < s.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, s.height), grid);
    }
    for (var y = 0.0; y < s.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(s.width, y), grid);
    }
    final rows = points
        .where((p) => p['lat'] is num && p['lng'] is num)
        .toList();
    if (rows.isEmpty) return;
    final cosLat = math.max(
      .05,
      math.cos((rows.first['lat'] as num).toDouble() * math.pi / 180),
    );
    final xs = [for (final p in rows) (p['lng'] as num).toDouble() * cosLat];
    final ys = [for (final p in rows) (p['lat'] as num).toDouble()];
    final minX = xs.reduce(math.min), maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min), maxY = ys.reduce(math.max);
    final dx = math.max(maxX - minX, .00012);
    final dy = math.max(maxY - minY, .00012);
    final scale = math.min((s.width - 55) / dx, (s.height - 48) / dy);
    Offset at(int i) => Offset(
      s.width / 2 + ((xs[i] - minX) - (maxX - minX) / 2) * scale,
      s.height / 2 - ((ys[i] - minY) - (maxY - minY) / 2) * scale,
    );
    Path? path;
    final segments = <Path>[];
    for (var i = 0; i < rows.length; i++) {
      if (path == null || rows[i]['segmentStart'] == true) {
        if (path != null) segments.add(path);
        path = Path()..moveTo(at(i).dx, at(i).dy);
      } else {
        path.lineTo(at(i).dx, at(i).dy);
      }
    }
    if (path != null) segments.add(path);
    for (final p in segments) {
      canvas.drawPath(
        p,
        Paint()
          ..color = const Color(0x80FF8E25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawPath(
        p,
        Paint()
          ..color = const Color(0xFFFFAA49)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final origin = at(0), end = at(rows.length - 1);
    canvas.drawCircle(origin, 7, Paint()..color = const Color(0xFF65D7F5));
    canvas.drawCircle(origin, 3, Paint()..color = Colors.white);
    canvas.drawCircle(
      end,
      10,
      Paint()
        ..color = const Color(0x66FF9B21)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(end, 5, Paint()..color = const Color(0xFFFFBA60));
    canvas.drawCircle(end, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MileageRecordedTrackPainter old) =>
      old.points != points;
}

class _MetricDetails extends StatefulWidget {
  final String metric;
  final DateTime month;
  const _MetricDetails({required this.metric, required this.month});
  @override
  State<_MetricDetails> createState() => _MetricDetailsState();
}

class _MetricDetailsState extends State<_MetricDetails> {
  late DateTime _month;
  _HomeMonthData? _total;
  ActivityBook? _book;
  TestPreferences? _prefs;
  double? _mileageOdometer;
  List<Map<String, dynamic>> _gpsRoutes = <Map<String, dynamic>>[];
  final _scroll = ScrollController();
  String? _error, _direction;
  bool _trips = false, _hideEmpty = true, _salaryDaysExpanded = false;
  int _loadId = 0;
  bool get _weight => ['Город', 'Район'].contains(widget.metric);
  bool get _fuel => ['Газ', 'Бензин'].contains(widget.metric);
  @override
  void initState() {
    super.initState();
    _month = widget.month;
    _homeDataRevision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _loadId++;
    _homeDataRevision.removeListener(_load);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = ++_loadId;
    try {
      final total = await _HomeMonthData.load(_month);
      final book = await ActivityRepository.load(_month);
      final prefs = await TestPreferences.getInstance();
      final routes = <Map<String, dynamic>>[];
      double? odometer;
      if (widget.metric == 'Пробег') {
        final journal = await TestStore.load();
        odometer = _mileageMonthOdometer(journal, _month);
        for (final shift in journal.shifts) {
          final started = DateTime.tryParse(shift['start']?.toString() ?? '');
          if (started == null ||
              started.year != _month.year ||
              started.month != _month.month)
            continue;
          final shiftId = shift['id']?.toString();
          if (shiftId == null) continue;
          final route = await GpsRouteStore.loadShift(shiftId);
          final points = <Map<String, dynamic>>[
            for (final p in (route['points'] as List? ?? const []))
              Map<String, dynamic>.from(p as Map),
          ];
          if (points.isNotEmpty)
            routes.add({
              'shiftId': shiftId,
              'started': started,
              'points': points,
              'km': (route['distanceKm'] as num?)?.toDouble() ?? 0.0,
            });
        }
        routes.sort(
          (a, b) =>
              (b['started'] as DateTime).compareTo(a['started'] as DateTime),
        );
      }
      if (mounted && id == _loadId)
        setState(() {
          _total = total;
          _book = book;
          _prefs = prefs;
          _mileageOdometer = odometer;
          _gpsRoutes = routes;
          _error = null;
        });
    } catch (_) {
      if (mounted && id == _loadId)
        setState(
          () => _error = 'Не удалось прочитать данные. Повторите попытку.',
        );
    }
  }

  void _monthTo(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _book = null;
      _total = null;
      _mileageOdometer = null;
      _gpsRoutes = [];
      _direction = null;
      _salaryDaysExpanded = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _load();
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final first = DateTime(_month.year, _month.month);
    final last = DateTime(_month.year, _month.month + 1, 0);
    final d = await showDatePicker(
      context: context,
      initialDate: ActivityBook.sameDay(first, now) ? now : first,
      firstDate: first,
      lastDate: last,
    );
    if (d != null && mounted) _day(d);
  }

  void _day(DateTime d) =>
      Navigator.of(context)
          .push<void>(_SceneRoute(builder: (_) => _DayDetails(date: d)));
  List<ActivityEntry> get _entries =>
      (_book?.entries ?? [])
          .where(
            (e) =>
                (_fuel ? e.kind == 'fuel' : e.kind == 'trip') &&
                e.type == widget.metric &&
                (_direction == null || e.direction == _direction),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  double? _dayValue(DateTime d, String metric) =>
      (_prefs?.get('home_day_${d.year}_${d.month}_${d.day}_$metric') as num?)
          ?.toDouble();
  Future<void> _filter() async {
    final options =
        (_book?.entries ?? [])
            .where((e) => e.kind == 'trip' && e.type == widget.metric)
            .map((e) => e.direction)
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final selected = await _pickQuickValue(context, 'Направление', [
      'Все направления',
      ...options,
    ]);
    if (selected != null && mounted)
      setState(
        () => _direction = selected == 'Все направления' ? null : selected,
      );
  }

  @override
  Widget build(BuildContext context) => widget.metric == 'Зарплата'
      ? _salaryScreen()
      : widget.metric == 'Пробег'
      ? _mileageScreen()
      : _DetailFrame(
          title: widget.metric,
          controller: _scroll,
          showHero: false,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Предыдущий месяц',
                  onPressed: () => _monthTo(-1),
                  icon: const Icon(Icons.chevron_left, color: _amber),
                ),
                Flexible(
                  child: _dt(
                    '${_garageMonths[_month.month - 1]} ${_month.year}',
                    size: 15,
                  ),
                ),
                IconButton(
                  tooltip: 'Следующий месяц',
                  onPressed: () => _monthTo(1),
                  icon: const Icon(Icons.chevron_right, color: _amber),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              _DetailGlass(child: _dt(_error!)),
              _detailButton('Повторить', _load),
            ] else if (_total == null || _book == null)
              const Center(child: CircularProgressIndicator(color: _amber))
            else
              ..._content(),
          ],
        );

  double? _mileageMonthOdometer(TestState book, DateTime month) {
    final shifts =
        book.shifts.where((shift) {
          final date = DateTime.tryParse((shift['start'] as String?) ?? '');
          return shift['currentKm'] is num &&
              date != null &&
              date.year == month.year &&
              date.month == month.month;
        }).toList()..sort(
          (a, b) => ((a['start'] as String?) ?? '').compareTo(
            (b['start'] as String?) ?? '',
          ),
        );
    if (shifts.isEmpty) return null;
    return (shifts.last['currentKm'] as num?)?.toDouble();
  }

  Future<void> _mileagePickDay() async {
    final now = DateTime.now();
    final first = DateTime(_month.year, _month.month);
    final last = DateTime(_month.year, _month.month + 1, 0);
    final inMonth = now.year == _month.year && now.month == _month.month;
    final selected = await showDatePicker(
      context: context,
      initialDate: inMonth ? now : first,
      firstDate: first,
      lastDate: last,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFC477),
            surface: Color(0xFF162129),
          ),
        ),
        child: child!,
      ),
    );
    if (selected != null && mounted) _day(selected);
  }

  double? _mileageDayValue(DateTime day) {
    final manual = _dayValue(day, 'mileage');
    if (manual != null && manual > 0) return manual;
    final gps = _gpsRoutes
        .where((r) => ActivityBook.sameDay(r['started'] as DateTime, day))
        .fold<double>(0.0, (sum, r) => sum + (r['km'] as double));
    return gps > 0 ? gps : manual;
  }

  double get _mileageMonthValue {
    final manual = _total?.mileage ?? 0.0;
    final gpsOnly = _gpsRoutes
        .where((r) {
          final day = r['started'] as DateTime;
          return (_dayValue(day, 'mileage') ?? 0.0) <= 0;
        })
        .fold<double>(0.0, (sum, r) => sum + (r['km'] as double));
    return manual + gpsOnly;
  }

  void _mileageOpenRoute(Map<String, dynamic> route) {
    final points = route['points'] as List<Map<String, dynamic>>;
    final started = route['started'] as DateTime;
    final km = (route['km'] as double);
    Navigator.of(context).push<void>(
      _SceneRoute(
        builder: (_) => _DetailFrame(
          title: 'GPS · ${_detailDate(started)}',
          scene: _Scene.cab,
          showHero: false,
          children: [
            const SizedBox(height: 14),
            Container(
              height: 215,
              decoration: BoxDecoration(
                color: const Color(0xE5102027),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x885E929E)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CustomPaint(
                  painter: _MileageRecordedTrackPainter(points),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            _DetailGlass(
              accent: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dt(
                    '${_fmt1(km)} км • ${points.length} GPS-точек',
                    color: _amber,
                    size: 17,
                  ),
                  const SizedBox(height: 8),
                  _dt(
                    'Начало записи: ${_detailTime(DateTime.tryParse(points.first['time']?.toString() ?? '') ?? started)}',
                    size: 13,
                  ),
                  _dt(
                    'Последняя точка: ${_detailTime(DateTime.tryParse(points.last['time']?.toString() ?? '') ?? started)}',
                    size: 13,
                  ),
                ],
              ),
            ),
            const _DetailGlass(
              child: Text(
                'Линия построена из записанных координат. '
                'Сетка декоративная, это не карта дорог. '
                'При выключенном GPS или свёрнутом приложении '
                'часть маршрута может отсутствовать.',
                style: TextStyle(color: Color(0xFFBDC9CE), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mileageRouteHistory() async {
    if (_gpsRoutes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS-маршрутов за выбранный месяц пока нет.'),
        ),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      _SceneRoute(
        builder: (_) => _DetailFrame(
          title: 'История маршрутов',
          scene: _Scene.cab,
          showHero: false,
          children: [
            const SizedBox(height: 12),
            _DetailGlass(
              child: Column(
                children: _separated([
                  for (final route in _gpsRoutes)
                    _detailRow(
                      '${_detailDate(route['started'] as DateTime)} · '
                          '${_detailTime(route['started'] as DateTime)}',
                      '${_fmt1(route['km'] as double)} км',
                      subtitle: '${(route['points'] as List).length} GPS-точек',
                      onTap: () => _mileageOpenRoute(route),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mileageRouteMap(double u) {
    final latest = _gpsRoutes.isEmpty ? null : _gpsRoutes.first;
    final points = latest == null
        ? <Map<String, dynamic>>[]
        : latest['points'] as List<Map<String, dynamic>>;
    final started = latest?['started'] as DateTime?;
    final length = latest?['km'] as double? ?? 0.0;
    return Container(
      height: 165 * u,
      margin: EdgeInsets.fromLTRB(13 * u, 9 * u, 13 * u, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17 * u),
        border: Border.all(color: const Color(0x86618D9D), width: .75 * u),
        color: const Color(0xC90A1921),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 14)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17 * u),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _MileageRecordedTrackPainter(points)),
            ),
            Positioned(
              top: 10 * u,
              left: 12 * u,
              right: 12 * u,
              child: Row(
                children: [
                  Icon(
                    Icons.route,
                    color: const Color(0xFFFFB45B),
                    size: 18 * u,
                  ),
                  SizedBox(width: 7 * u),
                  Expanded(
                    child: Text(
                      'Маршрут смены',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15 * u,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.gps_fixed,
                    color: points.isNotEmpty
                        ? const Color(0xFF69D7F2)
                        : const Color(0xFF8797A0),
                    size: 13 * u,
                  ),
                  SizedBox(width: 5 * u),
                  Text(
                    points.isNotEmpty ? 'GPS · запись' : 'GPS · ожидание',
                    style: TextStyle(
                      color: const Color(0xFFB9D5E0),
                      fontSize: 10 * u,
                    ),
                  ),
                ],
              ),
            ),
            if (points.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20 * u),
                  child: Text(
                    'Нет записанных GPS-точек.\n'
                    'Открой смену и разреши доступ к геолокации.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12 * u,
                      height: 1.4,
                      color: const Color(0xFFD3DFE2),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 10 * u,
              right: 10 * u,
              bottom: 9 * u,
              child: Material(
                color: const Color(0xD809151B),
                borderRadius: BorderRadius.circular(11 * u),
                child: InkWell(
                  onTap: _mileageRouteHistory,
                  borderRadius: BorderRadius.circular(11 * u),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * u,
                      vertical: 8 * u,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                started == null
                                    ? 'История маршрутов'
                                    : '${_detailDate(started)} · ${_fmt1(length)} км',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12 * u,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Реальные координаты · схема без карты дорог',
                                style: TextStyle(
                                  color: const Color(0xFF9AB8C5),
                                  fontSize: 9 * u,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: const Color(0xFFFFC57A),
                          size: 19 * u,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mileagePhoto(double u) => LayoutBuilder(
    builder: (context, box) {
      final r = box.maxWidth / 864.0;
      final current = _mileageOdometer == null
          ? ''
          : _mileageOdometer!.round().toString();
      return SizedBox(
        width: box.maxWidth,
        height: 554 * r,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/scenes/mileage_reference_instruments.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
            // Только внутреннее окно барабанов; металл и циферблаты из фото.
            Positioned(
              left: 294 * r,
              top: 364 * r,
              width: 188 * r,
              height: 73 * r,
              child: IgnorePointer(
                child: CustomPaint(painter: _MileageDrumPainter(current)),
              ),
            ),
            // Фото содержит старое число: перекрываем ТОЛЬКО область цифр.
            Positioned(
              left: 625 * r,
              top: 244 * r,
              width: 171 * r,
              height: 65 * r,
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6 * r),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF251F19),
                          Color(0xFF121D21),
                          Color(0xFF132229),
                        ],
                      ),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _total == null
                                  ? '—'
                                  : _fmtInt(_mileageMonthValue),
                              style: TextStyle(
                                fontSize: 50 * r,
                                color: const Color(0xFFF5E9D6),
                                fontWeight: FontWeight.w700,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xFF000000),
                                    blurRadius: 3,
                                    offset: Offset(1, 2),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 4 * r),
                            Padding(
                              padding: EdgeInsets.only(bottom: 8 * r),
                              child: Text(
                                'км',
                                style: TextStyle(
                                  fontSize: 18 * r,
                                  color: const Color(0xFFBDD1D7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _mileageScreen() => Scaffold(
    backgroundColor: const Color(0xFF080D11),
    body: LayoutBuilder(
      builder: (context, box) {
        final u = box.maxWidth / 354.5;
        return Stack(
          children: [
            const Positioned.fill(
              child: Image(
                image: AssetImage('assets/images/scenes/mileage.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.high,
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x33000000),
                        Color(0x22000000),
                        Color(0xC80A0E12),
                        Color(0xEA080D11),
                      ],
                      stops: [0, .29, .82, 1],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: ListView(
                key: const PageStorageKey('mileage-with-real-gps'),
                controller: _scroll,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 20 * u),
                children: [
                  _mileageHeader(u),
                  SizedBox(height: 7 * u),
                  Center(child: _mileageMonthSelector(u)),
                  _mileageRouteMap(u),
                  SizedBox(height: 5 * u),
                  _mileagePhoto(u),
                  SizedBox(height: 8 * u),
                  if (_error != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15 * u),
                      child: Column(
                        children: [
                          _DetailGlass(child: _dt(_error!)),
                          _detailButton('Повторить', _load),
                        ],
                      ),
                    )
                  else
                    _mileageDaysPanel(u),
                  SizedBox(height: 9 * u),
                  _mileageHistoryButton(u),
                  SizedBox(height: 12 * u),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14 * u,
                        color: const Color(0xFFA6B1B8),
                      ),
                      SizedBox(width: 8 * u),
                      Text(
                        'Данные из журнала и GPS',
                        style: TextStyle(
                          color: const Color(0xFFA6B1B8),
                          fontSize: 11 * u,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16 * u),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          _openGarageSection(context, 'Статистика', ''),
                      icon: Icon(
                        Icons.chevron_left,
                        color: const Color(0xFFABB7C1),
                        size: 19 * u,
                      ),
                      label: Text(
                        'К показателям',
                        style: TextStyle(
                          color: const Color(0xFFABB7C1),
                          fontSize: 13 * u,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _mileageHeader(double u) => SizedBox(
    height: 44 * u,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 15 * u),
      child: Row(
        children: [
          SizedBox(
            width: 26 * u,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              padding: EdgeInsets.zero,
              tooltip: 'Назад',
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20 * u,
              ),
            ),
          ),
          SizedBox(width: 9 * u),
          Text(
            'Пробег',
            style: TextStyle(
              fontSize: 17 * u,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'Действия',
            color: const Color(0xFF1C2327),
            icon: Icon(Icons.more_horiz, size: 24 * u, color: Colors.white),
            onSelected: (value) {
              if (value == 'day') _mileagePickDay();
              if (value == 'history') _mileageRouteHistory();
              if (value == 'stats')
                _openGarageSection(context, 'Статистика', '');
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'day',
                child: Text(
                  'Выбрать дату',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              PopupMenuItem(
                value: 'history',
                child: Text(
                  'История маршрутов',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              PopupMenuItem(
                value: 'stats',
                child: Text(
                  'Показатели',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _mileageMonthSelector(double u) => Container(
    width: 160 * u,
    height: 34 * u,
    decoration: BoxDecoration(
      color: const Color(0xE7192228),
      border: Border.all(color: const Color(0xB8818D93), width: .7 * u),
      borderRadius: BorderRadius.circular(22 * u),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 33 * u,
          child: IconButton(
            tooltip: 'Предыдущий месяц',
            padding: EdgeInsets.zero,
            onPressed: () => _monthTo(-1),
            icon: Icon(Icons.chevron_left, color: Colors.white, size: 21 * u),
          ),
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${_garageMonths[_month.month - 1]} ${_month.year}',
              maxLines: 1,
              style: TextStyle(color: Colors.white, fontSize: 13.5 * u),
            ),
          ),
        ),
        SizedBox(
          width: 33 * u,
          child: IconButton(
            tooltip: 'Следующий месяц',
            padding: EdgeInsets.zero,
            onPressed: () => _monthTo(1),
            icon: Icon(Icons.chevron_right, color: Colors.white, size: 21 * u),
          ),
        ),
      ],
    ),
  );

  Widget _mileageDaysPanel(double u) {
    final now = DateTime.now();
    final last = DateTime(_month.year, _month.month + 1, 0).day;
    final count = now.year == _month.year && now.month == _month.month
        ? now.day
        : last;
    final dates = <DateTime>[
      for (var day = count; day >= 1; day--)
        DateTime(_month.year, _month.month, day),
    ].where((day) => _mileageDayValue(day) != null).take(4).toList();

    const line = Color(0x6650575A);
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 184 * u),
      margin: EdgeInsets.symmetric(horizontal: 15 * u),
      padding: EdgeInsets.fromLTRB(14 * u, 12 * u, 14 * u, 9 * u),
      decoration: BoxDecoration(
        color: const Color(0xE51C1D1D),
        border: Border.all(color: const Color(0xC39E783F), width: .7 * u),
        borderRadius: BorderRadius.circular(12 * u),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Пробег по дням',
                    style: TextStyle(
                      fontSize: 16 * u,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Выбрать дату',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 30 * u,
                    minHeight: 28 * u,
                  ),
                  onPressed: _mileagePickDay,
                  icon: Icon(
                    Icons.calendar_month_outlined,
                    size: 19 * u,
                    color: const Color(0xFFC9D4D8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2 * u),
            Text(
              'Последние записи (всего за месяц: '
              '${_total == null ? '—' : _fmtInt(_mileageMonthValue)} км)',
              style: TextStyle(
                fontSize: 11.5 * u,
                color: const Color(0xFFA1A6A9),
              ),
            ),
            SizedBox(height: 11 * u),
            const Divider(height: 1, thickness: .7, color: line),
            if (_total == null || _book == null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 37 * u),
                child: Center(
                  child: SizedBox(
                    width: 22 * u,
                    height: 22 * u,
                    child: CircularProgressIndicator(
                      strokeWidth: 2 * u,
                      color: const Color(0xFFFFBF66),
                    ),
                  ),
                ),
              )
            else if (dates.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 31 * u),
                child: Text(
                  'За этот месяц записей пробега пока нет.',
                  style: TextStyle(
                    fontSize: 12 * u,
                    color: const Color(0xFFBDC5CB),
                  ),
                ),
              )
            else
              for (var i = 0; i < dates.length; i++) ...[
                InkWell(
                  onTap: () => _day(dates[i]),
                  child: SizedBox(
                    height: 36 * u,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _detailDate(dates[i]),
                            style: TextStyle(
                              color: const Color(0xFFF2F3F5),
                              fontSize: 13 * u,
                            ),
                          ),
                        ),
                        Text(
                          '${_fmtInt(_mileageDayValue(dates[i]) ?? 0)} км',
                          style: TextStyle(
                            color: const Color(0xFFF2F3F5),
                            fontSize: 13 * u,
                          ),
                        ),
                        SizedBox(width: 8 * u),
                        Icon(
                          Icons.chevron_right,
                          color: const Color(0xFFCCD4D8),
                          size: 20 * u,
                        ),
                      ],
                    ),
                  ),
                ),
                if (i != dates.length - 1)
                  const Divider(height: 1, thickness: .7, color: line),
              ],
          ],
        ),
      ),
    );
  }

  Widget _mileageHistoryButton(double u) => Container(
    margin: EdgeInsets.symmetric(horizontal: 15 * u),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xB16A919E), width: .7 * u),
      borderRadius: BorderRadius.circular(12 * u),
      color: const Color(0xC7102027),
      boxShadow: const [
        BoxShadow(
          color: Color(0x44000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _mileageRouteHistory,
        borderRadius: BorderRadius.circular(12 * u),
        child: SizedBox(
          height: 45 * u,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 13 * u),
            child: Row(
              children: [
                Icon(
                  Icons.route_outlined,
                  color: const Color(0xFF82DDF3),
                  size: 27 * u,
                ),
                SizedBox(width: 13 * u),
                Expanded(
                  child: Text(
                    'Открыть историю маршрутов',
                    style: TextStyle(color: Colors.white, fontSize: 12.5 * u),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white, size: 20 * u),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  // Salary uses its own image and overlay; every other metric keeps the
  // existing backdrop and its original navigation.
  Widget _salaryScreen() => Scaffold(
    backgroundColor: const Color(0xFF0A0E10),
    body: LayoutBuilder(
      builder: (context, box) {
        // These are coordinates in the 747x1536 salary backdrop.
        // Match BoxFit.cover, including the horizontal crop on narrower phones.
        final scale = math.max(box.maxWidth / 747.0, box.maxHeight / 1536.0);
        final offsetX = (747 * scale - box.maxWidth) / 2;
        final safe = MediaQuery.paddingOf(context);
        final availableHeight = math.max(
          0.0,
          box.maxHeight - safe.top - safe.bottom,
        );
        return Stack(
          children: [
            const Positioned.fill(
              child: Image(
                image: AssetImage('assets/images/salary_cab.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, .12, .33, .53, 1],
                      colors: [
                        Color(0x6504080A),
                        Color(0x0804080A),
                        Color(0x0004080A),
                        Color(0x0504080A),
                        Color(0x3504080A),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                key: const PageStorageKey('salary-screen'),
                controller: _scroll,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: availableHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        _salaryHeader(),
                        const SizedBox(height: 63),
                        const Expanded(child: SizedBox(height: 165)),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _DetailGlass(child: _dt(_error!)),
                                _detailButton('Повторить', _load),
                              ],
                            ),
                          )
                        else if (_total == null || _book == null)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(color: _amber),
                          )
                        else
                          _salaryPanel(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // The photographic month selector remains crisp; this foreground
            // supplies the current month and hit targets for the photo chevrons.
            Positioned(
              left: 230 * scale - offsetX,
              top: 126 * scale,
              width: 294 * scale,
              height: 57 * scale,
              child: _salaryMonthOverlay(),
            ),
            // The tablet is already in the photo: draw only its current amount.
            Positioned(
              left: 545 * scale - offsetX,
              top: 349 * scale,
              width: 141 * scale,
              height: 39 * scale,
              child: IgnorePointer(
                child: Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateZ(0.02)
                    ..rotateY(-0.09),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _total == null ? '—' : '${_fmtInt(_total!.salary)} ₸',
                        maxLines: 1,
                        style: TextStyle(
                          color: const Color(0xF0D4A35D),
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                          shadows: const [
                            Shadow(
                              color: Color(0x70000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _salaryHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(9, 4, 9, 0),
    child: Row(
      children: [
        SizedBox(
          width: 48,
          child: IconButton(
            tooltip: 'Назад',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: _paper, size: 20),
          ),
        ),
        const Expanded(
          child: Text(
            'Зарплата',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _paper,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: PopupMenuButton<String>(
            tooltip: 'Дополнительные действия',
            color: const Color(0xFF1C2226),
            icon: const Icon(Icons.more_horiz, color: _paper, size: 21),
            onSelected: (value) {
              if (value == 'day') _pickDay();
              if (value == 'stats') _salaryStatistics();
              if (value == 'home')
                Navigator.of(context).popUntil((route) => route.isFirst);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'day',
                child: Text('Выбрать дату', style: TextStyle(color: _paper)),
              ),
              PopupMenuItem(
                value: 'stats',
                child: Text('Показатели', style: TextStyle(color: _paper)),
              ),
              PopupMenuItem(
                value: 'home',
                child: Text('На главную', style: TextStyle(color: _paper)),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _salaryMonthOverlay() => Row(
    children: [
      Expanded(
        child: Semantics(
          button: true,
          label: 'Предыдущий месяц',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _monthTo(-1),
            child: const SizedBox.expand(),
          ),
        ),
      ),
      Expanded(
        flex: 4,
        child: Container(
          alignment: Alignment.center,
          // This hides the placeholder text printed in the reference image.
          decoration: BoxDecoration(
            color: const Color(0xFF1C1D1E),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            '${_garageMonths[_month.month - 1]} ${_month.year}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _paper,
              fontSize:
                  25 *
                  math.min(
                    MediaQuery.sizeOf(context).width / 747.0,
                    MediaQuery.sizeOf(context).height / 1536.0,
                  ),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
      Expanded(
        child: Semantics(
          button: true,
          label: 'Следующий месяц',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _monthTo(1),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ],
  );

  Widget _salaryPanel() {
    const line = Color(0x554F5557);
    const gold = Color(0xFFBA873C);
    final parts = const <(String, String)>[
      ('base_salary', 'Основной оклад'),
      ('weekend_pay', 'Выходные'),
      ('holiday_pay', 'Праздники'),
      ('paid_routes_pay', 'Платные рейсы'),
      ('city_pay', 'Городской вес'),
      ('region_pay', 'Районный вес'),
    ];
    final now = DateTime.now();
    final last = DateTime(_month.year, _month.month + 1, 0).day;
    final count = _month.year == now.year && _month.month == now.month
        ? now.day
        : last;
    final dates =
        [
              for (var day = count; day >= 1; day--)
                DateTime(_month.year, _month.month, day),
            ]
            .where((date) => !_hideEmpty || _dayValue(date, 'salary') != null)
            .toList();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      padding: const EdgeInsets.fromLTRB(16, 19, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xF21B1E20),
        border: Border.all(color: gold, width: 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x70000000),
            blurRadius: 26,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Состав зарплаты',
            style: TextStyle(
              color: _paper,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 9),
          for (final part in parts) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      part.$2,
                      style: const TextStyle(color: _paper, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _salaryPart(part.$1),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: _paper,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: .6,
              color: part.$1 == 'region_pay' ? gold : line,
            ),
          ],
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Отработано',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB4B6B8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _salaryPart('hours', unit: 'ч'),
                        style: const TextStyle(color: _paper, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(
                  thickness: 1,
                  color: Color(0x776B512F),
                  width: 26,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Норма',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB4B6B8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _salaryPart('norm_hours', unit: 'ч'),
                        style: const TextStyle(color: _paper, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('salary-show-days'),
              onTap: () =>
                  setState(() => _salaryDaysExpanded = !_salaryDaysExpanded),
              borderRadius: BorderRadius.circular(10),
              child: Ink(
                decoration: BoxDecoration(
                  color: const Color(0x52101619),
                  border: Border.all(color: gold),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _salaryDaysExpanded
                              ? 'Скрыть дни'
                              : 'Посмотреть по дням',
                          style: const TextStyle(color: _paper, fontSize: 12),
                        ),
                      ),
                      Icon(
                        _salaryDaysExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.chevron_right,
                        color: _paper,
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_salaryDaysExpanded) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'По дням',
                    style: TextStyle(color: _paper, fontSize: 16),
                  ),
                ),
                IconButton(
                  tooltip: 'Выбрать дату',
                  onPressed: _pickDay,
                  icon: const Icon(
                    Icons.calendar_month_outlined,
                    color: _amber,
                  ),
                ),
              ],
            ),
            if (dates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'За этот месяц записей пока нет.',
                  style: TextStyle(color: Color(0xFFAFB8BE), fontSize: 13),
                ),
              )
            else
              for (final date in dates) ...[
                const Divider(height: 1, thickness: .6, color: line),
                InkWell(
                  onTap: () => _day(date),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _detailDate(date),
                            style: TextStyle(
                              fontSize: 14,
                              color: date.weekday >= 6
                                  ? const Color(0xFFFFAA91)
                                  : _paper,
                            ),
                          ),
                        ),
                        Text(
                          _dailyText(date),
                          style: const TextStyle(color: _paper, fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          color: _paper,
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Spacer(),
              TextButton(
                onPressed: () => _openSalaryReport(context, _month),
                style: TextButton.styleFrom(
                  foregroundColor: _amber,
                  padding: EdgeInsets.zero,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Создать отчёт', style: TextStyle(fontSize: 11)),
                    SizedBox(width: 3),
                    Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _salaryStatistics() => _openGarageSection(context, 'Статистика', '');

  List<Widget> _content() {
    final total = _total!;
    final entries = _entries;
    final metric = widget.metric;
    final value = switch (metric) {
      'Город' => '${_fmt1(total.city)} т',
      'Район' => '${_fmt1(total.region)} т',
      'Газ' => '${_fmt1(total.gas)} л',
      'Бензин' => '${_fmt1(total.petrol)} л',
      'Пробег' => '${_fmtInt(total.mileage)} км',
      _ => '${_fmtInt(total.salary)} ₸',
    };
    final now = DateTime.now();
    final isCurrent = _month.year == now.year && _month.month == now.month;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final count = isCurrent ? now.day : days;
    final dates = [
      for (var i = count; i >= 1; i--) DateTime(_month.year, _month.month, i),
    ];
    return [
      _SceneSpace(scene: _sceneFor(metric), controlsHeight: 120),
      _SceneSummary(
        value: value,
        label: _fuel
            ? 'Получено за месяц'
            : _weight
            ? 'Перевезено за месяц'
            : metric == 'Пробег'
            ? 'За выбранный месяц'
            : 'Начислено за месяц',
      ),
      if (_weight) ...[
        _QuickSegment(
          values: const ['По дням', 'По рейсам'],
          selected: _trips ? 'По рейсам' : 'По дням',
          onChanged: (v) => setState(() => _trips = v == 'По рейсам'),
        ),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _filter,
                icon: const Icon(
                  Icons.filter_alt_outlined,
                  size: 17,
                  color: _amber,
                ),
                label: Text(
                  _direction ?? 'Все направления',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _amber, fontSize: 13),
                ),
              ),
            ),
            IconButton(
              tooltip: _hideEmpty ? 'Показать пустые дни' : 'Скрыть пустые дни',
              onPressed: () => setState(() => _hideEmpty = !_hideEmpty),
              icon: Icon(
                _hideEmpty
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: _ice,
              ),
            ),
          ],
        ),
      ],
      if (_fuel || (_weight && _trips)) ...[
        if (entries.isEmpty)
          _DetailGlass(
            child: _dt(
              'За этот месяц записей пока нет.',
              color: const Color(0xFFB3C6D0),
            ),
          )
        else
          _DetailGlass(
            child: Column(
              children: _separated([
                for (final e in entries)
                  _detailRow(
                    _fuel
                        ? _detailDate(e.date)
                        : e.direction.isEmpty
                        ? 'Направление не указано'
                        : e.direction,
                    _fuel
                        ? '${_fmt1(e.amount)} л'
                        : '${_fmtInt(e.amount * 1000)} кг',
                    subtitle: _fuel
                        ? _detailTime(e.date)
                        : '${_detailDate(e.date)} · ${_detailTime(e.date)}',
                    onTap: () => _day(e.date),
                  ),
              ]),
            ),
          ),
      ] else ...[
        Row(
          children: [
            Expanded(child: _dt('По дням', size: 16, weight: FontWeight.w500)),
            IconButton(
              tooltip: 'Выбрать дату',
              onPressed: _pickDay,
              icon: const Icon(Icons.calendar_month, color: _amber),
            ),
          ],
        ),
        _DetailGlass(
          child: Column(
            children: _separated([
              for (final d in dates)
                if (!_hideEmpty ||
                    (_weight
                        ? entries.any((e) => ActivityBook.sameDay(e.date, d))
                        : _dayValue(
                                d,
                                metric == 'Зарплата' ? 'salary' : 'mileage',
                              ) !=
                              null))
                  _detailRow(
                    _detailDate(d),
                    _weight ? _weightDay(entries, d) : _dailyText(d),
                    onTap: () => _day(d),
                    color: d.weekday >= 6 ? const Color(0xFFFFAA91) : null,
                  ),
            ]),
          ),
        ),
      ],
      const SizedBox(height: 8),
      if (_fuel)
        _detailButton(
          'Добавить заправку',
          () => _testEditor(context, 'fuel', initialType: metric),
          icon: Icons.add,
        ),
    ];
  }

  String _salaryPart(String key, {String unit = '₸'}) {
    final value = (_prefs?.get(
      'home_${_month.year}_${_month.month}_$key',
    ) as num?)?.toDouble();
    return value == null ? '—' : '${_fmtInt(value)} $unit';
  }

  String _weightDay(List<ActivityEntry> entries, DateTime d) {
    final rows = entries.where((e) => ActivityBook.sameDay(e.date, d));
    return rows.isEmpty
        ? '—'
        : '${_fmtInt(rows.fold<double>(0, (s, e) => s + e.amount) * 1000)} кг';
  }

  String _dailyText(DateTime d) {
    final value = _dayValue(
      d,
      widget.metric == 'Зарплата' ? 'salary' : 'mileage',
    );
    return value == null
        ? '—'
        : '${_fmtInt(value)} ${widget.metric == 'Зарплата' ? '₸' : 'км'}';
  }
}

Future<void> _openDaySummary(BuildContext context, DateTime day) async {
  await Navigator.of(context).push<void>(
    _SceneRoute<void>(
      builder: (_) => _DayDetails(date: DateTime(day.year, day.month, day.day)),
    ),
  );
}

double _summaryMileage(TestState b, DateTime day) => b.shifts
    .where(
      (s) =>
          TestState.dayKey(DateTime.parse(s['start'] as String)) ==
          TestState.dayKey(day),
    )
    .fold<double>(
      0,
      (value, s) =>
          value +
          (b.hasRecordedMileage(s)
              ? b.mileage(s)
              : (s['gpsKm'] as num?)?.toDouble() ?? 0),
    );

class _DayDetails extends StatelessWidget {
  final DateTime date;
  const _DayDetails({required this.date});
  static const gold = Color(0xFFD8AC65),
      blue = Color(0xFF62ADC0),
      white = Color(0xFFE6E9EA);
  Widget text(
    String s,
    double size, {
    Color color = white,
    FontWeight weight = FontWeight.w400,
    int lines = 1,
  }) => Text(
    s,
    maxLines: lines,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: 1.2,
    ),
  );
  Widget metric(String title, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF514936), width: .6),
          color: const Color(0x45081015),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 47),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text(title, 19, color: Colors.white70),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: text(
                      value,
                      36,
                      color: color,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  Widget record(
    BuildContext c,
    Map<String, dynamic> r,
    int index, {
    bool fuel = false,
  }) {
    final timestamp = DateTime.tryParse(r['date']?.toString() ?? '');
    final title = fuel
        ? r['type']?.toString() ?? 'Топливо'
        : r['direction']?.toString() ?? 'Без направления';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _testEditor(c, fuel ? 'fuel' : 'trip', entry: r),
        child: Container(
          height: 57,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF3E474D), width: .7),
            ),
          ),
          child: Row(
            children: [
              if (fuel)
                Icon(
                  r['type'] == 'Газ'
                      ? Icons.local_fire_department
                      : Icons.local_gas_station_outlined,
                  color: gold,
                  size: 32,
                )
              else
                Container(
                  width: 31,
                  height: 31,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: gold),
                  ),
                  child: text('${index + 1}', 18, color: gold),
                ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    text(title, 19),
                    text(
                      '${timestamp == null ? '' : _detailTime(timestamp)}${fuel ? ' · Выдано' : ' · ${r['type'] ?? ''}'}',
                      13,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              text(
                '${_fmt1((r['amount'] as num?)?.toDouble() ?? 0)} ${fuel ? 'л' : 'кг'}',
                25,
                color: gold,
                weight: FontWeight.w600,
              ),
              const Icon(Icons.chevron_right, color: Colors.white54, size: 25),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFF071017),
      body: _TestLive(
        builder: (b) {
          final key = TestState.dayKey(date);
          final shifts =
              b.shifts
                  .where(
                    (s) =>
                        TestState.dayKey(
                          DateTime.parse(s['start'] as String),
                        ) ==
                        key,
                  )
                  .toList()
                ..sort(
                  (a, z) =>
                      (a['start'] as String).compareTo(z['start'] as String),
                );
          final ids = shifts.map((s) => s['id']).toSet();
          final rows =
              b.records.where((r) => ids.contains(r['shiftId'])).toList()..sort(
                (a, z) => (a['date'] as String).compareTo(z['date'] as String),
              );
          final trips = rows.where((r) => r['kind'] == 'trip').toList(),
              fuel = rows.where((r) => r['kind'] == 'fuel').toList();
          final stats = b.statistics(date, day: date);
          // Same monthly base-pay allocation as the existing statistics table.
          var dayBases = 0.0;
          for (
            var i = 1;
            i <= DateTime(date.year, date.month + 1, 0).day;
            i++
          ) {
            dayBases +=
                b.statistics(
                  date,
                  day: DateTime(date.year, date.month, i),
                )['base_salary'] ??
                0;
          }
          final factor = dayBases == 0
              ? 1.0
              : (b.statistics(date)['base_salary'] ?? 0) / dayBases;
          final salary =
              (stats['salary'] ?? 0) -
              (stats['base_salary'] ?? 0) * (1 - factor);
          final items = <(String, String, IconData, Color)>[
            (
              'Город',
              '${_fmt1(stats['city_kg'] ?? 0)} кг',
              Icons.location_city,
              gold,
            ),
            (
              'Район',
              '${_fmt1(stats['region_kg'] ?? 0)} кг',
              Icons.location_on_outlined,
              blue,
            ),
            ('Рейсы', '${trips.length}', Icons.local_shipping_outlined, gold),
            (
              'Пробег',
              '${_fmt1(_summaryMileage(b, date))} км',
              Icons.speed_outlined,
              blue,
            ),
            (
              'Газ (выдано)',
              '${_fmt1(stats['gas'] ?? 0)} л',
              Icons.local_fire_department,
              gold,
            ),
            (
              'Бензин (выдано)',
              '${_fmt1(stats['petrol'] ?? 0)} л',
              Icons.local_gas_station_outlined,
              blue,
            ),
            (
              'Часы',
              '${_fmt1(stats['all_hours'] ?? 0)} ч',
              Icons.access_time,
              gold,
            ),
            ('Заработано', '${_fmt1(salary)} ₸', Icons.payments_outlined, blue),
          ];
          return LayoutBuilder(
            builder: (context, box) {
              final scale = box.maxWidth / 864,
                  top = MediaQuery.viewPaddingOf(context).top;
              final height = math.max(box.maxHeight, 1536 * scale + top);
              Widget at(double x, double y, double w, double h, Widget child) =>
                  Positioned(
                    left: x,
                    top: y,
                    width: w,
                    height: h,
                    child: child,
                  );
              final scene = SizedBox(
                width: 864,
                height: 1536,
                child: Stack(
                  children: [
                    at(
                      50,
                      52,
                      78,
                      78,
                      _GasTap(
                        label: 'Назад',
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xD909131A),
                            border: Border.all(color: gold, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    at(
                      185,
                      65,
                      535,
                      59,
                      Center(
                        child: text(
                          'Сводка за день',
                          40,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    at(
                      225,
                      133,
                      440,
                      39,
                      Center(
                        child: text(
                          '${_detailDate(date)} ${date.year}',
                          25,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    at(
                      756,
                      66,
                      58,
                      58,
                      PopupMenuButton<String>(
                        tooltip: 'Действия за день',
                        icon: const Icon(
                          Icons.more_horiz,
                          color: gold,
                          size: 32,
                        ),
                        color: const Color(0xFF101A21),
                        onSelected: (value) {
                          if (value == 'gps') {
                            Navigator.of(context).push<void>(
                              _SceneRoute<void>(
                                builder: (_) => _DayGps(day: date),
                              ),
                            );
                          } else {
                            _dayActions(context, date);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'gps',
                            child: Text('GPS за день'),
                          ),
                          PopupMenuItem(
                            value: 'shift',
                            child: Text('Действия со сменой'),
                          ),
                        ],
                      ),
                    ),
                    at(
                      145,
                      255,
                      551,
                      58,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.grass, color: gold, size: 42),
                          const SizedBox(width: 18),
                          text('М Е Л Ь Н И Ц А', 26),
                        ],
                      ),
                    ),
                    for (var i = 0; i < 8; i++)
                      at(
                        144.0 + (i % 2) * 280,
                        326.0 + (i ~/ 2) * 107,
                        280,
                        107,
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onLongPress: (i == 3 || i == 6) && shifts.isNotEmpty
                              ? () {
                                  HapticFeedback.mediumImpact();
                                  showDialog<void>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => _DayMetricEditor(
                                      day: date,
                                      mileage: i == 3,
                                      book: b,
                                      shifts: shifts,
                                    ),
                                  );
                                }
                              : null,
                          child: metric(
                            items[i].$1,
                            items[i].$2,
                            items[i].$3,
                            items[i].$4,
                          ),
                        ),
                      ),
                    at(
                      150,
                      768,
                      543,
                      87,
                      shifts.isEmpty
                          ? Center(
                              child: text(
                                'За этот день смен нет',
                                21,
                                color: Colors.white60,
                              ),
                            )
                          : ListView.builder(
                              primary: false,
                              physics: const ClampingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: shifts.length,
                              itemBuilder: (c, i) {
                                final s = shifts[i],
                                    start = DateTime.parse(
                                      s['start'] as String,
                                    ),
                                    end = DateTime.tryParse(
                                      s['end']?.toString() ?? '',
                                    );
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.schedule,
                                        color: gold,
                                        size: 31,
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            text(
                                              'Открыта ${_detailTime(start)}  ·  ${end == null ? 'Ещё не завершена' : 'Завершена ${_detailTime(end)}'}',
                                              18,
                                            ),
                                            text(
                                              TestState.mileageSource(s) ==
                                                      MileageSource.manual
                                                  ? (s['manualKm'] == null
                                                        ? 'Пробег будет указан при завершении'
                                                        : '${_fmt1(b.mileage(s))} км · введено вручную')
                                                  : 'Одометр: ${s['startKm']} → ${s['odometerSet'] == true ? s['currentKm'] : '—'} км',
                                              15,
                                              color: Colors.white60,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    at(
                      99,
                      934,
                      658,
                      52,
                      Row(
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined,
                            color: gold,
                            size: 43,
                          ),
                          const SizedBox(width: 20),
                          text('Рейсы за день', 27, weight: FontWeight.w600),
                        ],
                      ),
                    ),
                    at(
                      96,
                      1003,
                      670,
                      163,
                      trips.isEmpty
                          ? Center(
                              child: text(
                                'Рейсов за этот день нет',
                                20,
                                color: Colors.white60,
                              ),
                            )
                          : ListView.builder(
                              primary: false,
                              physics: const ClampingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemExtent: 57,
                              itemCount: trips.length,
                              itemBuilder: (c, i) =>
                                  record(context, trips[i], i),
                            ),
                    ),
                    at(
                      99,
                      1211,
                      658,
                      53,
                      Row(
                        children: [
                          const Icon(
                            Icons.local_gas_station_outlined,
                            color: gold,
                            size: 39,
                          ),
                          const SizedBox(width: 20),
                          text('Выдача топлива', 27, weight: FontWeight.w600),
                        ],
                      ),
                    ),
                    at(
                      96,
                      1274,
                      670,
                      111,
                      fuel.isEmpty
                          ? Center(
                              child: text(
                                'Выдач топлива за этот день нет',
                                20,
                                color: Colors.white60,
                              ),
                            )
                          : ListView.builder(
                              primary: false,
                              physics: const ClampingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemExtent: 57,
                              itemCount: fuel.length,
                              itemBuilder: (c, i) =>
                                  record(context, fuel[i], i, fuel: true),
                            ),
                    ),
                  ],
                ),
              );
              return SingleChildScrollView(
                child: SizedBox(
                  height: height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: _ExtendedArtwork(
                            asset: 'assets/images/scenes/day_summary.png',
                            topInset: top,
                          ),
                        ),
                      ),
                      Positioned(
                        top: top,
                        left: 0,
                        right: 0,
                        height: 1536 * scale,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.topCenter,
                          child: MediaQuery.withClampedTextScaling(
                            minScaleFactor: 1,
                            maxScaleFactor: 1,
                            child: scene,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

class _DayMetricEditor extends StatefulWidget {
  final DateTime day;
  final bool mileage;
  final TestState book;
  final List<Map<String, dynamic>> shifts;
  const _DayMetricEditor({
    required this.day,
    required this.mileage,
    required this.book,
    required this.shifts,
  });
  @override
  State<_DayMetricEditor> createState() => _DayMetricEditorState();
}

class _DayMetricEditorState extends State<_DayMetricEditor> {
  late final initial = <String, String>{
    for (final s in widget.shifts)
      s['id'] as String:
          (widget.mileage ? widget.book.mileage(s) : widget.book.hours(s))
              .toString()
              .replaceFirst(RegExp(r'\.0$'), ''),
  };
  late final fields = <String, TextEditingController>{
    for (final e in initial.entries)
      e.key: TextEditingController(text: e.value),
  };
  bool busy = false;
  String? error;
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    for (final controller in fields.values) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    }
  }

  Future<void> save() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await TestStore.correctShiftMetrics({
        for (final e in fields.entries)
          if (e.value.text != initial[e.key])
            e.key:
                double.tryParse(e.value.text.trim().replaceAll(',', '.')) ??
                double.nan,
      }, mileage: widget.mileage);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        setState(() {
          busy = false;
          error = _testError(e);
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      backgroundColor: const Color(0xFF11191D),
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF776044), width: .8),
      ),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22),
      actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      scrollable: true,
      title: Text(
        widget.mileage ? 'Пробег, км' : 'Отработано часов',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE6E9EA),
        ),
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_detailDate(widget.day)} ${widget.day.year}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF929B9F)),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < widget.shifts.length; i++) ...[
              if (widget.shifts.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Смена с ${_detailTime(DateTime.parse(widget.shifts[i]['start'] as String))}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF929B9F),
                    ),
                  ),
                ),
              TextField(
                controller: fields[widget.shifts[i]['id']],
                autofocus: i == 0,
                enabled: !busy,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: !widget.mileage,
                ),
                textInputAction: i == widget.shifts.length - 1
                    ? TextInputAction.done
                    : TextInputAction.next,
                onSubmitted: (_) {
                  if (i == widget.shifts.length - 1) {
                    save();
                  } else {
                    FocusScope.of(context).nextFocus();
                  }
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    widget.mileage ? RegExp(r'[0-9]') : RegExp(r'[0-9.,]'),
                  ),
                ],
                style: const TextStyle(fontSize: 26, color: Color(0xFFE6E9EA)),
                cursorColor: const Color(0xFFD8AC65),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFF0B1216),
                  suffixText: widget.mileage ? 'км' : 'ч',
                  suffixStyle: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF929B9F),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF60523F)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD8AC65)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (error != null)
              Text(
                error!,
                style: const TextStyle(fontSize: 13, color: Color(0xFFD59C89)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text(
            'Отмена',
            style: TextStyle(color: Color(0xFF929B9F)),
          ),
        ),
        TextButton(
          onPressed: busy ? null : save,
          child: Text(
            busy ? 'Сохранение…' : 'Сохранить',
            style: const TextStyle(
              color: Color(0xFFD8AC65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

// Gas detail scene. Uses the same shift-accounting dates as the home totals.
const _gasGold = Color(0xFFD8AC65);
const _gasBlue = Color(0xFF53B9D2);
const _gasWhite = Color(0xFFE6E9EA);

class _GasDashboard extends StatefulWidget {
  final DateTime month;
  final bool petrol;
  const _GasDashboard({required this.month, this.petrol = false});
  @override
  State<_GasDashboard> createState() => _GasDashboardState();
}

class _GasDashboardState extends State<_GasDashboard> {
  late DateTime month;
  String get fuel => widget.petrol ? 'Бензин' : 'Газ';
  String get fuelGenitive => widget.petrol ? 'бензина' : 'газа';
  Color get fuelAccent => widget.petrol ? const Color(0xFFE5765F) : _gasBlue;
  TestState? book;
  String? error;
  int tab = 0, request = 0;
  @override
  void initState() {
    super.initState();
    month = DateTime(widget.month.year, widget.month.month);
    TestStore.revision.addListener(load);
    load();
  }

  @override
  void dispose() {
    request++;
    TestStore.revision.removeListener(load);
    super.dispose();
  }

  Future<void> load() async {
    final id = ++request;
    try {
      final value = await TestStore.load();
      if (mounted && id == request)
        setState(() {
          book = value;
          error = null;
        });
    } catch (_) {
      if (mounted && id == request)
        setState(() => error = 'Не удалось загрузить выдачи $fuelGenitive');
    }
  }

  DateTime dateOf(Map<String, dynamic> row) => book!.recordDay(row);
  double amount(Map<String, dynamic> row) =>
      (row['amount'] as num?)?.toDouble() ?? 0;
  List<Map<String, dynamic>> get rows =>
      (book?.records ?? <Map<String, dynamic>>[])
          .where(
            (r) =>
                r['kind'] == 'fuel' &&
                r['type'] == fuel &&
                dateOf(r).year == month.year &&
                dateOf(r).month == month.month,
          )
          .toList()
        ..sort((a, b) {
          final day = dateOf(b).compareTo(dateOf(a));
          return day != 0
              ? day
              : (b['date'] as String).compareTo(a['date'] as String);
        });
  Future<void> pickMonth() async {
    var year = month.year;
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: const Color(0xFF101A21),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) => SafeArea(
          child: SizedBox(
            height: 340,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Предыдущий год',
                      onPressed: year > 2000
                          ? () => update(() => year--)
                          : null,
                      icon: const Icon(Icons.chevron_left, color: _gasGold),
                    ),
                    Text(
                      '$year',
                      style: const TextStyle(color: _gasWhite, fontSize: 20),
                    ),
                    IconButton(
                      tooltip: 'Следующий год',
                      onPressed: year < 2100
                          ? () => update(() => year++)
                          : null,
                      icon: const Icon(Icons.chevron_right, color: _gasGold),
                    ),
                  ],
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    children: List.generate(
                      12,
                      (i) => TextButton(
                        onPressed: () =>
                            Navigator.pop(sheet, DateTime(year, i + 1)),
                        child: Text(
                          _garageMonths[i],
                          style: TextStyle(
                            color: year == month.year && i + 1 == month.month
                                ? _gasGold
                                : _gasWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => month = selected);
  }

  Future<void> add() async {
    await _testEditor(context, 'fuel', initialType: fuel);
  }

  Future<void> openDay(DateTime day) => _openDaySummary(context, day);
  @override
  Widget build(BuildContext context) {
    final entries = rows;
    final total = entries.fold<double>(0, (s, r) => s + amount(r));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    double since(DateTime first) => entries
        .where((r) {
          final d = dateOf(r);
          return !d.isBefore(first) &&
              d.isBefore(today.add(const Duration(days: 1)));
        })
        .fold<double>(0, (s, r) => s + amount(r));
    final daily = List<double>.filled(
      DateTime(month.year, month.month + 1, 0).day,
      0,
    );
    final counts = List<double>.filled(daily.length, 0);
    final groups = <int, List<Map<String, dynamic>>>{};
    for (final r in entries) {
      final d = dateOf(r).day;
      daily[d - 1] += amount(r);
      counts[d - 1]++;
      (groups[d] ??= []).add(r);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final latest = entries.isEmpty ? null : entries.first;
    final average = entries.isEmpty ? 0.0 : total / entries.length;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF050B10),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final scale = math.min(
              constraints.maxWidth / 864,
              (constraints.maxHeight -
                      MediaQuery.paddingOf(context).bottom -
                      160) /
                  900,
            );
            final sceneWidth = 864 * scale;
            final headerTop = math.max(
              28.0,
              MediaQuery.paddingOf(context).top / scale + 8,
            );
            // Keep the scene's upper frame below the entire safe header row.
            final sceneTop = math.max(0.0, headerTop + 88 + 16 - 125);
            Widget at(double x, double y, double w, double h, Widget child) =>
                Positioned(left: x, top: y, width: w, height: h, child: child);
            final hero = SizedBox(
              width: 864,
              height: 900 + sceneTop,
              child: Transform.translate(
                offset: Offset(0, sceneTop),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    at(
                      25,
                      headerTop - sceneTop,
                      88,
                      88,
                      _GasTap(
                        label: 'Назад',
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xB0081016),
                            border: Border.all(color: _gasGold, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: _gasGold,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    at(
                      widget.petrol ? 292 : 340,
                      headerTop - sceneTop,
                      widget.petrol ? 315 : 200,
                      85,
                      Row(
                        children: [
                          Icon(
                            widget.petrol
                                ? Icons.local_gas_station_outlined
                                : Icons.local_fire_department_outlined,
                            color: widget.petrol ? fuelAccent : _gasGold,
                            size: 65,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            fuel,
                            style: const TextStyle(
                              color: _gasWhite,
                              fontSize: 44,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    at(
                      621,
                      headerTop + 6 - sceneTop,
                      215,
                      70,
                      _GasTap(
                        label: 'Выбрать месяц',
                        onTap: pickMonth,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xCF0A141B),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: _gasGold),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                '${_garageMonths[month.month - 1]} ${month.year} ⌄',
                                style: const TextStyle(
                                  color: _gasWhite,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    at(
                      300,
                      205,
                      278,
                      113,
                      Column(
                        children: [
                          Text(
                            'Выдано $fuelGenitive за месяц',
                            style: const TextStyle(
                              color: _gasWhite,
                              fontSize: 21,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${_fmt1(total)} л',
                                style: const TextStyle(
                                  color: _gasGold,
                                  fontSize: 65,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _GasWall(
                      points: const [
                        Offset(57, 162),
                        Offset(235, 203),
                        Offset(234, 327),
                        Offset(57, 287),
                      ],
                      title: 'Сегодня',
                      value: '${_fmt1(since(today))} л',
                      icon: Icons.calendar_month_outlined,
                      color: _gasGold,
                      values: daily,
                      onTap: () => openDay(today),
                    ),
                    _GasWall(
                      points: const [
                        Offset(58, 350),
                        Offset(235, 390),
                        Offset(235, 506),
                        Offset(57, 475),
                      ],
                      title: 'За неделю',
                      value: '${_fmt1(since(monday))} л',
                      icon: Icons.calendar_month_outlined,
                      color: _gasBlue,
                      values: daily,
                      onTap: () => setState(() => tab = 1),
                    ),
                    _GasWall(
                      points: const [
                        Offset(56, 539),
                        Offset(235, 570),
                        Offset(235, 681),
                        Offset(55, 664),
                      ],
                      title: 'За месяц',
                      value: '${_fmt1(total)} л',
                      icon: Icons.bar_chart,
                      color: _gasGold,
                      values: daily,
                      onTap: () => setState(() => tab = 1),
                    ),
                    _GasWall(
                      points: const [
                        Offset(636, 204),
                        Offset(813, 165),
                        Offset(813, 292),
                        Offset(636, 329),
                      ],
                      title: 'Средняя выдача',
                      value: '${_fmt1(average)} л',
                      icon: null,
                      color: _gasBlue,
                      values: daily,
                      onTap: () => setState(() => tab = 1),
                    ),
                    _GasWall(
                      points: const [
                        Offset(636, 389),
                        Offset(813, 351),
                        Offset(813, 477),
                        Offset(636, 509),
                      ],
                      title: 'Выдач',
                      value: '${entries.length}',
                      icon: Icons.local_gas_station_outlined,
                      color: _gasBlue,
                      values: counts,
                      onTap: () => setState(() => tab = 2),
                    ),
                    _GasWall(
                      points: const [
                        Offset(636, 569),
                        Offset(813, 541),
                        Offset(813, 664),
                        Offset(636, 681),
                      ],
                      title: 'Последняя выдача',
                      value: latest == null
                          ? '—'
                          : '${_fmt1(amount(latest))} л',
                      icon: Icons.access_time,
                      color: _gasGold,
                      values: daily,
                      line: true,
                      onTap: latest == null
                          ? () => setState(() => tab = 2)
                          : () => _testEditor(context, 'fuel', entry: latest),
                    ),
                  ],
                ),
              ),
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: _ExtendedArtwork(
                    asset: widget.petrol
                        ? 'assets/images/scenes/petrol_dashboard.png'
                        : 'assets/images/scenes/gas_dashboard.png',
                    topInset: sceneTop * scale,
                    imageWidth: sceneWidth,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 6,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: constraints.maxWidth,
                        height: (900 + sceneTop) * scale,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: MediaQuery.withClampedTextScaling(
                            minScaleFactor: 1,
                            maxScaleFactor: 1,
                            child: hero,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            for (var i = 0; i < 3; i++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: i == 2 ? 0 : 4,
                                  ),
                                  child: _GasTap(
                                    label: const [
                                      'Выдачи',
                                      'Статистика',
                                      'Журнал',
                                    ][i],
                                    onTap: () => setState(() => tab = i),
                                    child: Container(
                                      height: 36,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(13),
                                        color: tab == i
                                            ? const Color(0xD9453215)
                                            : const Color(0xD909131B),
                                        border: Border.all(
                                          color: tab == i
                                              ? _gasGold
                                              : const Color(0xFF45505A),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            const [
                                              Icons.local_gas_station_outlined,
                                              Icons.bar_chart,
                                              Icons.receipt_long_outlined,
                                            ][i],
                                            color: tab == i
                                                ? _gasGold
                                                : _gasWhite,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              const [
                                                'Выдачи',
                                                'Статистика',
                                                'Журнал',
                                              ][i],
                                              maxLines: 1,
                                              style: const TextStyle(
                                                color: _gasWhite,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(14, 7, 14, 0),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xED0B141C),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFF655D4B),
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    tab == 0
                                        ? Icons.calendar_month_outlined
                                        : tab == 1
                                        ? Icons.bar_chart
                                        : Icons.receipt_long,
                                    color: _gasGold,
                                    size: 21,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      [
                                        '$fuel по дням',
                                        'Статистика $fuelGenitive',
                                        'Журнал выдач',
                                      ][tab],
                                      style: const TextStyle(
                                        color: _gasWhite,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Добавить выдачу $fuelGenitive',
                                    onPressed: add,
                                    visualDensity: VisualDensity.compact,
                                    iconSize: 21,
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: _gasGold,
                                    ),
                                  ),
                                ],
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ListView(
                                  key: ValueKey(
                                    '$fuel-$tab-${month.year}-${month.month}',
                                  ),
                                  shrinkWrap: true,
                                  primary: false,
                                  padding: EdgeInsets.zero,
                                  children: [
                                    if (error != null) ...[
                                      Text(
                                        error!,
                                        style: const TextStyle(
                                          color: _gasWhite,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: load,
                                        child: const Text('Повторить'),
                                      ),
                                    ] else if (book == null)
                                      const Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: _gasGold,
                                          ),
                                        ),
                                      )
                                    else if (entries.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 30,
                                        ),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Text(
                                                'В этом месяце выдач $fuelGenitive нет',
                                                style: const TextStyle(
                                                  color: _gasWhite,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              TextButton.icon(
                                                onPressed: add,
                                                icon: const Icon(
                                                  Icons.add,
                                                  color: _gasGold,
                                                ),
                                                label: const Text(
                                                  'Добавить выдачу',
                                                  style: TextStyle(
                                                    color: _gasGold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else if (tab == 0) ...[
                                      for (final d in days)
                                        _GasDayRow(
                                          fuel: fuel,
                                          accent: fuelAccent,
                                          day: DateTime(
                                            month.year,
                                            month.month,
                                            d,
                                          ),
                                          total: groups[d]!.fold<double>(
                                            0,
                                            (s, r) => s + amount(r),
                                          ),
                                          count: groups[d]!.length,
                                          onTap: () => openDay(
                                            DateTime(
                                              month.year,
                                              month.month,
                                              d,
                                            ),
                                          ),
                                        ),
                                    ] else if (tab == 2) ...[
                                      for (final r in entries)
                                        _GasJournalRow(
                                          accent: fuelAccent,
                                          row: r,
                                          day: dateOf(r),
                                          onTap: () => openDay(dateOf(r)),
                                        ),
                                    ] else ...[
                                      Text(
                                        '${_garageMonths[month.month - 1]} ${month.year} · литры по дням',
                                        style: const TextStyle(
                                          color: Color(0xFFADB8BF),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        height: 150,
                                        width: double.infinity,
                                        child: CustomPaint(
                                          painter: _GasChart(
                                            daily,
                                            _gasBlue,
                                            labels: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      _GasStatRow(
                                        'Всего за месяц',
                                        '${_fmt1(total)} л',
                                      ),
                                      _GasStatRow(
                                        'Количество выдач',
                                        '${entries.length}',
                                      ),
                                      _GasStatRow(
                                        'Средняя выдача',
                                        '${_fmt1(average)} л',
                                      ),
                                      _GasStatRow(
                                        'Максимальная выдача',
                                        '${_fmt1(entries.map(amount).reduce(math.max))} л',
                                      ),
                                      _GasStatRow(
                                        'Дней с выдачами',
                                        '${days.length}',
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GasTap extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback onTap;
  const _GasTap({
    required this.label,
    required this.child,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: child,
    ),
  );
}

class _GasStatRow extends StatelessWidget {
  final String label, value;
  const _GasStatRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _gasWhite, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _gasGold,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _GasDayRow extends StatelessWidget {
  final String fuel;
  final Color accent;
  final DateTime day;
  final double total;
  final int count;
  final VoidCallback onTap;
  const _GasDayRow({
    this.fuel = 'Газ',
    this.accent = _gasBlue,
    required this.day,
    required this.total,
    required this.count,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => _gasRecordFrame(
    onTap,
    Row(
      children: [
        SizedBox(
          width: 46,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day.day.toString().padLeft(2, '0'),
                style: const TextStyle(color: _gasWhite, fontSize: 20),
              ),
              Text(
                _garageMonths[day.month - 1],
                style: const TextStyle(color: Color(0xFFABB8BF), fontSize: 9),
              ),
            ],
          ),
        ),
        Icon(Icons.location_on_outlined, color: accent, size: 21),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$fuel · Выдача',
                style: const TextStyle(color: _gasWhite, fontSize: 10),
              ),
              const SizedBox(height: 2),
              Text(
                count == 1 ? 'Выдано водителю' : 'Выдач за день: $count',
                style: const TextStyle(color: Color(0xFFA3AEB6), fontSize: 10),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 58,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              '${_fmt1(total)} л',
              maxLines: 1,
              style: const TextStyle(
                color: _gasWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const Icon(Icons.chevron_right, color: _gasWhite, size: 22),
      ],
    ),
  );
}

class _GasJournalRow extends StatelessWidget {
  final Color accent;
  final Map<String, dynamic> row;
  final DateTime day;
  final VoidCallback onTap;
  const _GasJournalRow({
    this.accent = _gasBlue,
    required this.row,
    required this.day,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final time = DateTime.tryParse(row['date']?.toString() ?? '');
    final note = row['note']?.toString().trim() ?? '';
    return _gasRecordFrame(
      onTap,
      Row(
        children: [
          Icon(Icons.local_gas_station_outlined, color: accent, size: 25),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_detailDate(day)}${time == null ? '' : ' · ${_detailTime(time)}'}',
                  style: const TextStyle(color: _gasWhite, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  note.isEmpty
                      ? 'Выдано водителю · нажмите для изменения'
                      : note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFA3AEB6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_fmt1((row['amount'] as num).toDouble())} л',
            style: const TextStyle(color: _gasWhite, fontSize: 16),
          ),
          const Icon(Icons.chevron_right, color: _gasGold, size: 20),
        ],
      ),
    );
  }
}

Widget _gasRecordFrame(VoidCallback tap, Widget child) => Padding(
  padding: const EdgeInsets.only(top: 4),
  child: _GasTap(
    label: 'Открыть выдачи топлива',
    onTap: tap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF424B52)),
        gradient: const LinearGradient(
          colors: [Color(0xA5202B32), Color(0xCF08121A)],
        ),
      ),
      child: child,
    ),
  ),
);

class _GasWall extends StatelessWidget {
  final List<Offset> points;
  final String title, value;
  final IconData? icon;
  final Color color;
  final List<double> values;
  final VoidCallback onTap;
  final bool line;
  const _GasWall({
    required this.points,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.values,
    required this.onTap,
    this.line = false,
  });
  @override
  Widget build(BuildContext context) {
    final p0 = points[0], p1 = points[1], p2 = points[2], p3 = points[3];
    final dx1 = p1.dx - p2.dx,
        dx2 = p3.dx - p2.dx,
        dy1 = p1.dy - p2.dy,
        dy2 = p3.dy - p2.dy;
    final dx3 = p0.dx - p1.dx + p2.dx - p3.dx,
        dy3 = p0.dy - p1.dy + p2.dy - p3.dy;
    final det = dx1 * dy2 - dx2 * dy1;
    final g = (dx3 * dy2 - dx2 * dy3) / det, h = (dx1 * dy3 - dx3 * dy1) / det;
    final matrix = Matrix4.identity()
      ..setEntry(0, 0, (p1.dx - p0.dx + g * p1.dx) / 220)
      ..setEntry(0, 1, (p3.dx - p0.dx + h * p3.dx) / 180)
      ..setEntry(0, 3, p0.dx)
      ..setEntry(1, 0, (p1.dy - p0.dy + g * p1.dy) / 220)
      ..setEntry(1, 1, (p3.dy - p0.dy + h * p3.dy) / 180)
      ..setEntry(1, 3, p0.dy)
      ..setEntry(3, 0, g / 220)
      ..setEntry(3, 1, h / 180);
    return Positioned.fill(
      child: Align(
        alignment: Alignment.topLeft,
        child: Transform(
          transform: matrix,
          child: SizedBox(
            width: 220,
            height: 180,
            child: _GasTap(
              label: '$title: $value',
              onTap: onTap,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: color, size: 45),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    color: _gasWhite,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                    color: _gasWhite,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _GasChart(values, color, line: line),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GasChart extends CustomPainter {
  final List<double> values;
  final Color color;
  final bool line, labels;
  const _GasChart(
    this.values,
    this.color, {
    this.line = false,
    this.labels = false,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final bottom = size.height - (labels ? 20 : 2);
    final top = labels ? 12.0 : 3.0;
    final peak = values.fold<double>(0, (a, b) => math.max(a, b));
    final width = size.width - (labels ? 30 : 0);
    final left = labels ? 30.0 : 0.0;
    final grid = Paint()
      ..color = color.withValues(alpha: .14)
      ..strokeWidth = .6;
    for (var i = 0; i < 4; i++) {
      final y = bottom - (bottom - top) * i / 3;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
    }
    if (values.isEmpty) return;
    final step = width / values.length;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = left + (i + .5) * step;
      final height = peak <= 0 ? 0.0 : values[i] / peak * (bottom - top);
      if (line) {
        if (i == 0) {
          path.moveTo(x, bottom - height);
        } else {
          path.lineTo(x, bottom - height);
        }
      } else {
        canvas.drawRect(
          Rect.fromLTWH(x - step * .31, top, step * .62, bottom - top),
          Paint()..color = color.withValues(alpha: .08),
        );
        if (height > 0)
          canvas.drawRect(
            Rect.fromLTWH(x - step * .31, bottom - height, step * .62, height),
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [color.withValues(alpha: .4), color],
              ).createShader(Offset.zero & size),
          );
      }
    }
    if (line)
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    if (labels) {
      void text(String value, double x, double y) {
        final p = TextPainter(
          text: TextSpan(
            text: value,
            style: const TextStyle(color: Color(0xFF9AABB5), fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        p.paint(canvas, Offset(x, y));
      }

      text(_fmt1(peak), 0, 0);
      text('0', 10, bottom - 10);
      for (var i = 0; i < values.length; i++) {
        if (i == 0 || i == values.length - 1 || (i + 1) % 5 == 0)
          text('${i + 1}', left + i * step, bottom + 5);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GasChart old) =>
      old.values != values ||
      old.color != color ||
      old.line != line ||
      old.labels != labels;
}

class _MileageReference extends StatefulWidget {
  final DateTime month;
  const _MileageReference({required this.month});
  @override
  State<_MileageReference> createState() => _MileageReferenceState();
}

class _MileageReferenceState extends State<_MileageReference> {
  late DateTime month = DateTime(widget.month.year, widget.month.month);
  int tab = 0, request = 0;
  bool reading = false;
  Timer? timer;
  final travelSeconds = <String, int>{};
  static const gold = Color(0xFFE0B16A),
      blue = Color(0xFF36BADD),
      white = Color(0xFFE8EDEE);
  @override
  void initState() {
    super.initState();
    loadTravel();
    timer = Timer.periodic(const Duration(seconds: 15), (_) => loadTravel());
    TestStore.revision.addListener(loadTravel);
  }

  @override
  void dispose() {
    request++;
    timer?.cancel();
    TestStore.revision.removeListener(loadTravel);
    super.dispose();
  }

  Future<void> loadTravel() async {
    if (reading) return;
    reading = true;
    final token = ++request;
    final selected = month;
    try {
      final b = await TestStore.load();
      final result = <String, int>{};
      for (final shift in b.shifts) {
        final date = DateTime.parse(shift['start'] as String);
        if (date.year != selected.year || date.month != selected.month)
          continue;
        final pts = await GpsRouteStore.points(shift['id'] as String);
        var seconds = 0;
        for (var i = 1; i < pts.length; i++) {
          final a = DateTime.tryParse(pts[i - 1]['time']?.toString() ?? '');
          final z = DateTime.tryParse(pts[i]['time']?.toString() ?? '');
          if (a == null || z == null) continue;
          final dt = z.difference(a).inSeconds;
          if (dt > 0 &&
              dt <= 120 &&
              ((pts[i]['speed'] as num?)?.toDouble() ?? 0) > .5)
            seconds += dt;
        }
        if (pts.isNotEmpty) result[shift['id'] as String] = seconds;
      }
      if (mounted && token == request && month == selected)
        setState(() {
          travelSeconds
            ..clear()
            ..addAll(result);
        });
    } catch (_) {
      /* GPS time remains unavailable; do not substitute shift duration. */
    } finally {
      reading = false;
    }
  }

  double km(TestState b, Map<String, dynamic> s) => b.hasRecordedMileage(s)
      ? b.mileage(s)
      : (s['gpsKm'] as num?)?.toDouble() ?? b.mileage(s);
  String destination(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    return value.split(RegExp(r'\s*(?:→|->|—|–)\s*')).last.trim();
  }

  List<String> destinations(TestState b, List<Map<String, dynamic>> shifts) => {
    for (final s in shifts)
      for (final r in b.forShift(s['id'] as String))
        if (r['kind'] == 'trip' && destination(r['direction']).isNotEmpty)
          destination(r['direction']),
  }.toList();
  Future<void> pickMonth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: month,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Выберите месяц',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (date != null && mounted) {
      setState(() {
        month = DateTime(date.year, date.month);
        travelSeconds.clear();
      });
      loadTravel();
    }
  }

  void route(Map<String, dynamic> shift) => Navigator.push(
    context,
    _SceneRoute<void>(
      builder: (c) => Scaffold(
        backgroundColor: const Color(0xFF08131B),
        appBar: AppBar(
          backgroundColor: const Color(0xFF101B22),
          title: const Text('Маршрут смены'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _detailDate(DateTime.parse(shift['start'] as String)),
                  style: const TextStyle(color: gold),
                ),
              ),
              Expanded(
                child: ShiftRouteMap(
                  shiftId: shift['id'] as String,
                  paused: shift['gpsStatus'] == 'paused',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  void day(TestState b, DateTime date, List<Map<String, dynamic>> shifts) {
    _openDaySummary(context, date);
  }

  BoxDecoration panel() => BoxDecoration(
    borderRadius: BorderRadius.circular(19),
    border: Border.all(color: const Color(0xAA8E754F), width: 1),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xF0192228), Color(0xF5060D13), Color(0xED15222A)],
    ),
    boxShadow: const [
      BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4)),
    ],
  );
  Widget text(String s, double size, {Color color = white}) => Text(
    s,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(color: color, fontSize: size, height: 1.15),
  );
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFF060D13),
      body: _TestLive(
        builder: (b) {
          final shifts =
              b.shifts.where((s) {
                final d = DateTime.parse(s['start'] as String);
                return d.year == month.year && d.month == month.month;
              }).toList()..sort(
                (a, z) =>
                    (z['start'] as String).compareTo(a['start'] as String),
              );
          final grouped = <DateTime, List<Map<String, dynamic>>>{};
          for (final s in shifts) {
            final d = DateTime.parse(s['start'] as String);
            (grouped[DateTime(d.year, d.month, d.day)] ??= []).add(s);
          }
          final days = grouped.keys.toList()..sort((a, z) => z.compareTo(a));
          double sum(List<Map<String, dynamic>> list) =>
              list.fold<double>(0, (v, s) => v + km(b, s));
          final total = sum(shifts), now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final monday = today.subtract(Duration(days: today.weekday - 1));
          final week = sum(
            shifts.where((s) {
              final d = DateTime.parse(s['start'] as String);
              return !d.isBefore(monday) &&
                  d.isBefore(today.add(const Duration(days: 1)));
            }).toList(),
          );
          final daily = List<double>.generate(
            DateTime(month.year, month.month + 1, 0).day,
            (i) => sum(grouped[DateTime(month.year, month.month, i + 1)] ?? []),
          );
          final seconds = travelSeconds.values.fold<int>(0, (a, z) => a + z);
          final elapsed = travelSeconds.isEmpty
              ? '—'
              : '${seconds ~/ 3600} ч ${seconds ~/ 60 % 60} мин';
          final names = destinations(b, shifts);
          return LayoutBuilder(
            builder: (context, box) {
              final scale = box.maxWidth / 864;
              final safe = MediaQuery.paddingOf(context).top;
              Widget at(double x, double y, double w, double h, Widget child) =>
                  Positioned(
                    left: x,
                    top: y,
                    width: w,
                    height: h,
                    child: child,
                  );
              Widget action(
                String label,
                IconData icon,
                VoidCallback tap, {
                bool selected = false,
              }) => _GasTap(
                label: label,
                onTap: tap,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(42),
                    border: Border.all(
                      color: selected ? gold : const Color(0xFF596C77),
                      width: 1.7,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: selected
                          ? const [Color(0xE86F4819), Color(0xF5111515)]
                          : const [Color(0xDD29333A), Color(0xF3050D13)],
                    ),
                    boxShadow: selected
                        ? const [
                            BoxShadow(color: Color(0x667A4E17), blurRadius: 12),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: selected ? gold : white, size: 38),
                      const SizedBox(width: 14),
                      text(label, 23),
                    ],
                  ),
                ),
              );
              final scene = SizedBox(
                width: 864,
                height: 1536,
                child: Stack(
                  children: [
                    at(
                      29,
                      30,
                      68,
                      68,
                      _GasTap(
                        label: 'Назад',
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xD0080E13),
                            border: Border.all(color: gold, width: 2),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: gold,
                            size: 38,
                          ),
                        ),
                      ),
                    ),
                    at(
                      308,
                      22,
                      300,
                      80,
                      Row(
                        children: [
                          const Icon(Icons.add_road, color: gold, size: 69),
                          const SizedBox(width: 19),
                          text('Пробег', 43),
                        ],
                      ),
                    ),
                    at(
                      638,
                      32,
                      204,
                      62,
                      _GasTap(
                        label: 'Выбрать месяц',
                        onTap: pickMonth,
                        child: Container(
                          decoration: panel(),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              text(
                                '${_garageMonths[month.month - 1]} ${month.year}',
                                20,
                              ),
                              const Icon(
                                Icons.expand_more,
                                color: white,
                                size: 25,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    at(
                      286,
                      379,
                      61,
                      40,
                      const CustomPaint(painter: _MileageRestNeedle()),
                    ),
                    at(
                      337,
                      276,
                      195,
                      28,
                      Center(child: text('Пробег за месяц', 23)),
                    ),
                    at(
                      337,
                      312,
                      195,
                      65,
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: total, end: total),
                        duration: const Duration(milliseconds: 500),
                        builder: (_, v, __) =>
                            CustomPaint(painter: _ReferenceDrum(v.round())),
                      ),
                    ),
                    at(400, 382, 65, 26, Center(child: text('км', 21))),
                    _GasWall(
                      points: const [
                        Offset(50, 151),
                        Offset(203, 183),
                        Offset(203, 296),
                        Offset(50, 266),
                      ],
                      title: 'Сегодня',
                      value: '${_fmt1(sum(grouped[today] ?? []))} км',
                      icon: Icons.add_road,
                      color: blue,
                      values: daily,
                      onTap: () => day(b, today, grouped[today] ?? []),
                    ),
                    _GasWall(
                      points: const [
                        Offset(51, 336),
                        Offset(203, 365),
                        Offset(203, 461),
                        Offset(51, 442),
                      ],
                      title: 'За неделю',
                      value: '${_fmt1(week)} км',
                      icon: Icons.add_road,
                      color: blue,
                      values: daily,
                      onTap: () => setState(() => tab = 2),
                    ),
                    _GasWall(
                      points: const [
                        Offset(52, 505),
                        Offset(203, 526),
                        Offset(203, 628),
                        Offset(52, 619),
                      ],
                      title: 'За месяц',
                      value: '${_fmt1(total)} км',
                      icon: Icons.add_road,
                      color: gold,
                      values: daily,
                      onTap: () => setState(() => tab = 2),
                    ),
                    _GasWall(
                      points: const [
                        Offset(661, 178),
                        Offset(826, 144),
                        Offset(826, 283),
                        Offset(661, 318),
                      ],
                      title: 'Средний за день',
                      value:
                          '${_fmt1(days.isEmpty ? 0 : total / days.length)} км',
                      icon: Icons.route,
                      color: blue,
                      values: daily,
                      onTap: () => setState(() => tab = 2),
                    ),
                    _GasWall(
                      points: const [
                        Offset(665, 354),
                        Offset(825, 328),
                        Offset(825, 468),
                        Offset(665, 492),
                      ],
                      title: 'Время в пути',
                      value: elapsed,
                      icon: Icons.access_time,
                      color: blue,
                      values: days.reversed
                          .map(
                            (d) => (grouped[d] ?? []).fold<double>(
                              0,
                              (v, s) => v + (travelSeconds[s['id']] ?? 0) / 60,
                            ),
                          )
                          .toList(),
                      line: true,
                      onTap: () => setState(() => tab = 1),
                    ),
                    at(
                      706,
                      585,
                      119,
                      95,
                      _GasTap(
                        label: 'Направления',
                        onTap: () => setState(() => tab = 1),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: panel(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final name in names.take(3))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        color: blue,
                                        size: 14,
                                      ),
                                      Expanded(child: text(name, 12)),
                                    ],
                                  ),
                                ),
                              if (names.isEmpty)
                                text(
                                  'Нет маршрутов',
                                  13,
                                  color: Colors.white60,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    at(
                      36,
                      806,
                      282,
                      79,
                      action('Добавить пробег', Icons.add_circle_outline, () {
                        setState(() => tab = 0);
                        _showShiftForm(context, shift: b.active);
                      }, selected: tab == 0),
                    ),
                    at(
                      328,
                      806,
                      250,
                      79,
                      action(
                        'Маршруты',
                        Icons.add_road,
                        () => setState(() => tab = 1),
                        selected: tab == 1,
                      ),
                    ),
                    at(
                      588,
                      806,
                      240,
                      79,
                      action(
                        'Статистика',
                        Icons.show_chart,
                        () => setState(() => tab = 2),
                        selected: tab == 2,
                      ),
                    ),
                    at(
                      35,
                      910,
                      794,
                      520,
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                        decoration: panel(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 12,
                                bottom: 16,
                              ),
                              child: text(
                                tab == 0
                                    ? 'Пробег по дням'
                                    : tab == 1
                                    ? 'Маршруты по дням'
                                    : 'Статистика пробега',
                                30,
                              ),
                            ),
                            Expanded(
                              child: tab == 2
                                  ? Column(
                                      children: [
                                        Text(
                                          '${_fmt1(total)} км за месяц',
                                          style: const TextStyle(
                                            color: gold,
                                            fontSize: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Expanded(
                                          child: CustomPaint(
                                            size: const Size(
                                              double.infinity,
                                              300,
                                            ),
                                            painter: _GasChart(
                                              daily,
                                              gold,
                                              line: true,
                                              labels: true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        text(
                                          'Среднее за день со сменой · ${_fmt1(days.isEmpty ? 0 : total / days.length)} км',
                                          20,
                                          color: Colors.white70,
                                        ),
                                      ],
                                    )
                                  : days.isEmpty
                                  ? Center(
                                      child: text(
                                        'За этот месяц пробег не записан',
                                        24,
                                        color: Colors.white60,
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: EdgeInsets.zero,
                                      itemCount: days.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 7),
                                      itemBuilder: (c, i) {
                                        final date = days[i],
                                            list = grouped[date]!;
                                        final dest = destinations(b, list);
                                        final types =
                                            {
                                                  for (final s in list)
                                                    for (final r in b.forShift(
                                                      s['id'] as String,
                                                    ))
                                                      if (r['kind'] == 'trip')
                                                        r['type']?.toString() ??
                                                            '',
                                                }
                                                .where((v) => v.isNotEmpty)
                                                .join(' · ');
                                        return _GasTap(
                                          label:
                                              '${_detailDate(date)}, ${dest.join(', ')}, ${_fmt1(sum(list))} км',
                                          onTap: () => day(b, date, list),
                                          child: Container(
                                            height: 79,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                            ),
                                            decoration: panel(),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 45,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      text(
                                                        '${date.day}'.padLeft(
                                                          2,
                                                          '0',
                                                        ),
                                                        29,
                                                      ),
                                                      text(
                                                        const [
                                                          'Пн',
                                                          'Вт',
                                                          'Ср',
                                                          'Чт',
                                                          'Пт',
                                                          'Сб',
                                                          'Вс',
                                                        ][date.weekday - 1],
                                                        13,
                                                        color: Colors.white60,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 9),
                                                SizedBox(
                                                  width: 100,
                                                  child: text(
                                                    _garageMonths[date.month -
                                                        1],
                                                    20,
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.location_on_outlined,
                                                  color: blue,
                                                  size: 33,
                                                ),
                                                const SizedBox(width: 15),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      text(
                                                        dest.isEmpty
                                                            ? 'Направление не указано'
                                                            : dest.join(', '),
                                                        22,
                                                      ),
                                                      const SizedBox(height: 5),
                                                      text(
                                                        types.isEmpty
                                                            ? 'Смена'
                                                            : types,
                                                        17,
                                                        color: Colors.white54,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                text(
                                                  '${_fmt1(sum(list))} км',
                                                  27,
                                                ),
                                                const SizedBox(width: 16),
                                                const Icon(
                                                  Icons.chevron_right,
                                                  color: white,
                                                  size: 30,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
              return SingleChildScrollView(
                child: SizedBox(
                  width: box.maxWidth,
                  height: math.max(
                    box.maxHeight,
                    1536 * scale + safe + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _ExtendedArtwork(
                          asset: 'assets/images/scenes/mileage_dashboard.png',
                          topInset: safe,
                        ),
                      ),
                      Positioned(
                        top: safe,
                        left: 0,
                        width: box.maxWidth,
                        height: 1536 * scale,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: MediaQuery.withClampedTextScaling(
                            minScaleFactor: 1,
                            maxScaleFactor: 1,
                            child: scene,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

class _ReferenceDrum extends CustomPainter {
  final int value;
  const _ReferenceDrum(this.value);
  @override
  void paint(Canvas c, Size s) {
    final digits = value.toString().padLeft(5, '0');
    final n = digits.length;
    final width = s.width / n;
    final frame = RRect.fromRectAndRadius(
      Offset.zero & s,
      const Radius.circular(5),
    );
    c.drawRRect(frame, Paint()..color = const Color(0xFF09121A));
    for (var i = 0; i < n; i++) {
      final r = Rect.fromLTWH(i * width + 2, 3, width - 4, s.height - 6);
      c.drawRect(
        r,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF101A21),
              Color(0xFF416071),
              Color(0xFF0A1219),
              Color(0xFF263842),
              Color(0xFF080D11),
            ],
            stops: [0, .3, .52, .8, 1],
          ).createShader(r),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: digits[i],
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: s.height * .71,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFDEE9EA),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        c,
        Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2),
      );
      c.drawLine(
        Offset(r.left, r.center.dy),
        Offset(r.right, r.center.dy),
        Paint()
          ..color = const Color(0xAA04090D)
          ..strokeWidth = 1,
      );
    }
    c.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF678190),
    );
  }

  @override
  bool shouldRepaint(covariant _ReferenceDrum old) => old.value != value;
}

class _MileageRestNeedle extends CustomPainter {
  const _MileageRestNeedle();
  @override
  void paint(Canvas c, Size s) {
    final a = Offset(2, s.height - 3), b = Offset(s.width - 3, 2);
    c.drawLine(
      a,
      b,
      Paint()
        ..strokeWidth = 7
        ..color = const Color(0xAAEFA84C)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    c.drawLine(
      a,
      b,
      Paint()
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFDA9A),
    );
  }

  @override
  bool shouldRepaint(covariant _MileageRestNeedle old) => false;
}

// Город и район: общий вес по дням, реальные направления и журнал рейсов.
class _DistrictDashboard extends StatefulWidget {
  final DateTime month;
  final bool city;
  const _DistrictDashboard({required this.month, this.city = false});
  @override
  State<_DistrictDashboard> createState() => _DistrictDashboardState();
}

class _DistrictDashboardState extends State<_DistrictDashboard> {
  late DateTime month = DateTime(widget.month.year, widget.month.month);
  int tab = 0;
  String get tripType => widget.city ? 'Город' : 'Район';
  String get missingDirection =>
      widget.city ? 'Направление не указано' : 'Район не указан';
  static const gold = Color(0xFFE0B16A),
      blue = Color(0xFF36BADD),
      white = Color(0xFFE8EDEE);
  double weight(Iterable<Map<String, dynamic>> rows) => rows.fold<double>(
    0,
    (v, r) => v + ((r['amount'] as num?)?.toDouble() ?? 0),
  );
  List<String> names(Iterable<Map<String, dynamic>> rows) {
    final found = <String, String>{};
    for (final r in rows) {
      final destination = (r['direction']?.toString() ?? '')
          .split(RegExp(r'\s*(?:→|->|—|–)\s*'))
          .last;
      for (final part in destination.split(',')) {
        final name = part.trim();
        if (name.isNotEmpty) found.putIfAbsent(name.toLowerCase(), () => name);
      }
    }
    return found.values.toList();
  }

  String kg(double value) => '${_fmt1(value)} кг';
  Widget text(String value, double size, {Color color = white}) => Text(
    value,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(color: color, fontSize: size, height: 1.15),
  );
  BoxDecoration glass({bool selected = false}) => BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: selected ? gold : const Color(0xAA6E777B),
      width: 1.3,
    ),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: selected
          ? const [Color(0xDD6D491B), Color(0xF0081117)]
          : const [Color(0xCE202B32), Color(0xEF071016)],
    ),
  );
  Future<void> pickMonth() async {
    var year = month.year;
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: const Color(0xFF101A21),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) => SafeArea(
          child: SizedBox(
            height: 340,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: year > 2000
                          ? () => update(() => year--)
                          : null,
                      icon: const Icon(Icons.chevron_left, color: gold),
                    ),
                    Text(
                      '$year',
                      style: const TextStyle(color: white, fontSize: 20),
                    ),
                    IconButton(
                      onPressed: year < 2100
                          ? () => update(() => year++)
                          : null,
                      icon: const Icon(Icons.chevron_right, color: gold),
                    ),
                  ],
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    children: List.generate(
                      12,
                      (i) => TextButton(
                        onPressed: () =>
                            Navigator.pop(sheet, DateTime(year, i + 1)),
                        child: Text(
                          _garageMonths[i],
                          style: TextStyle(
                            color: year == month.year && i + 1 == month.month
                                ? gold
                                : white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => month = selected);
  }

  Widget record(Map<String, dynamic> row, DateTime day, {double factor = 1}) {
    final destination = names([row]);
    final time = DateTime.tryParse(row['date']?.toString() ?? '');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: const Icon(Icons.location_on_outlined, color: blue),
      title: Text(
        destination.isEmpty ? missingDirection : destination.join(', '),
        style: TextStyle(color: white, fontSize: 15 * factor),
      ),
      subtitle: Text(
        '${_detailDate(day)}${time == null ? '' : ' · ${_detailTime(time)}'}',
        style: TextStyle(color: Colors.white60, fontSize: 12 * factor),
      ),
      trailing: Text(
        kg(weight([row])),
        style: TextStyle(color: gold, fontSize: 16 * factor),
      ),
      onTap: () => openDay(day),
    );
  }

  void openDay(DateTime date) {
    _openDaySummary(context, date);
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFF060D13),
      body: _TestLive(
        builder: (b) {
          bool district(Map<String, dynamic> r) =>
              r['kind'] == 'trip' && r['type'] == tripType;
          final all = b.records.where(district).toList();
          final rows =
              all.where((r) {
                final d = b.recordDay(r);
                return d.year == month.year && d.month == month.month;
              }).toList()..sort(
                (a, z) => (z['date'] as String).compareTo(a['date'] as String),
              );
          final grouped = <DateTime, List<Map<String, dynamic>>>{};
          for (final r in rows) {
            final d = b.recordDay(r);
            (grouped[DateTime(d.year, d.month, d.day)] ??= []).add(r);
          }
          final days = grouped.keys.toList()..sort((a, z) => z.compareTo(a));
          final now = DateTime.now(), total = weight(rows);
          final today = DateTime(now.year, now.month, now.day);
          final monday = today.subtract(Duration(days: today.weekday - 1));
          final week = all.where((r) {
            final d = b.recordDay(r);
            return !d.isBefore(monday) &&
                d.isBefore(today.add(const Duration(days: 1)));
          });
          final daily = List<double>.generate(
            DateTime(month.year, month.month + 1, 0).day,
            (i) =>
                weight(grouped[DateTime(month.year, month.month, i + 1)] ?? []),
          );
          final counts = List<double>.generate(
            daily.length,
            (i) => (grouped[DateTime(month.year, month.month, i + 1)] ?? [])
                .length
                .toDouble(),
          );
          final stops = List<double>.generate(
            daily.length,
            (i) =>
                names(grouped[DateTime(month.year, month.month, i + 1)] ?? [])
                    .length
                    .toDouble(),
          );
          return LayoutBuilder(
            builder: (context, box) {
              final scale = box.maxWidth / 864,
                  safe = MediaQuery.paddingOf(context).top;
              Widget at(double x, double y, double w, double h, Widget child) =>
                  Positioned(
                    left: x,
                    top: y,
                    width: w,
                    height: h,
                    child: child,
                  );
              Widget action(String label, IconData icon, int index) => _GasTap(
                label: label,
                onTap: () => setState(() => tab = index),
                child: Container(
                  decoration: glass(selected: tab == index),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: tab == index ? gold : white, size: 40),
                      const SizedBox(width: 18),
                      text(label, 25),
                    ],
                  ),
                ),
              );
              final scene = SizedBox(
                width: 864,
                height: 1536,
                child: Stack(
                  children: [
                    at(
                      35,
                      34,
                      70,
                      70,
                      _GasTap(
                        label: 'Назад',
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xCF071016),
                            border: Border.all(color: gold, width: 2),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: gold,
                            size: 38,
                          ),
                        ),
                      ),
                    ),
                    at(
                      303,
                      25,
                      290,
                      76,
                      Row(
                        children: [
                          Icon(
                            widget.city
                                ? Icons.location_city
                                : Icons.map_outlined,
                            color: gold,
                            size: 69,
                          ),
                          const SizedBox(width: 20),
                          text(tripType, 43),
                        ],
                      ),
                    ),
                    at(400, 100, 120, 2, Container(color: gold)),
                    at(
                      649,
                      39,
                      184,
                      63,
                      _GasTap(
                        label: 'Выбрать месяц',
                        onTap: pickMonth,
                        child: Container(
                          decoration: glass(selected: true),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                text(
                                  '${_garageMonths[month.month - 1]} ${month.year}',
                                  19,
                                ),
                                const Icon(
                                  Icons.expand_more,
                                  color: white,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    at(
                      302,
                      229,
                      260,
                      30,
                      Center(
                        child: text(
                          widget.city
                              ? 'Вес по городу за месяц'
                              : 'Вес по району за месяц',
                          23,
                        ),
                      ),
                    ),
                    at(
                      298,
                      264,
                      268,
                      53,
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            kg(total),
                            style: const TextStyle(
                              color: gold,
                              fontSize: 55,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _GasWall(
                      points: const [
                        Offset(55, 183),
                        Offset(213, 236),
                        Offset(213, 338),
                        Offset(55, 291),
                      ],
                      title: 'Сегодня',
                      value: kg(
                        weight(
                          all.where(
                            (r) =>
                                TestState.dayKey(b.recordDay(r)) ==
                                TestState.dayKey(today),
                          ),
                        ),
                      ),
                      icon: Icons.local_shipping_outlined,
                      color: gold,
                      values: daily,
                      onTap: () => openDay(today),
                    ),
                    _GasWall(
                      points: const [
                        Offset(53, 367),
                        Offset(213, 406),
                        Offset(213, 518),
                        Offset(53, 485),
                      ],
                      title: 'За неделю',
                      value: kg(weight(week)),
                      icon: Icons.calendar_month_outlined,
                      color: gold,
                      values: daily,
                      onTap: () => setState(() => tab = 1),
                    ),
                    _GasWall(
                      points: const [
                        Offset(53, 547),
                        Offset(213, 574),
                        Offset(213, 683),
                        Offset(53, 677),
                      ],
                      title: 'За месяц',
                      value: kg(total),
                      icon: Icons.bar_chart,
                      color: gold,
                      values: daily,
                      onTap: () => setState(() => tab = 1),
                    ),
                    _GasWall(
                      points: const [
                        Offset(650, 236),
                        Offset(808, 192),
                        Offset(808, 310),
                        Offset(650, 350),
                      ],
                      title: 'Средний за день',
                      value: kg(days.isEmpty ? 0 : total / days.length),
                      icon: Icons.bar_chart,
                      color: blue,
                      values: daily,
                      onTap: () => setState(() => tab = 1),
                    ),
                    _GasWall(
                      points: const [
                        Offset(650, 411),
                        Offset(808, 375),
                        Offset(808, 508),
                        Offset(650, 537),
                      ],
                      title: widget.city
                          ? 'Городских рейсов'
                          : 'Районных рейсов',
                      value: '${rows.length}',
                      icon: Icons.local_shipping_outlined,
                      color: blue,
                      values: counts,
                      onTap: () => setState(() => tab = 2),
                    ),
                    _GasWall(
                      points: const [
                        Offset(650, 587),
                        Offset(808, 557),
                        Offset(808, 687),
                        Offset(650, 696),
                      ],
                      title: 'Направлений',
                      value: '${names(rows).length}',
                      icon: Icons.location_on_outlined,
                      color: blue,
                      values: stops,
                      line: true,
                      onTap: () => setState(() => tab = 0),
                    ),
                    at(45, 889, 261, 69, action('Маршруты', Icons.add_road, 0)),
                    at(
                      316,
                      889,
                      249,
                      69,
                      action('Статистика', Icons.bar_chart, 1),
                    ),
                    at(
                      577,
                      889,
                      242,
                      69,
                      action('Журнал', Icons.receipt_long_outlined, 2),
                    ),
                    at(
                      51,
                      991,
                      761,
                      448,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                color: gold,
                                size: 40,
                              ),
                              const SizedBox(width: 17),
                              Expanded(
                                child: text(
                                  tab == 0
                                      ? 'Вес по дням'
                                      : tab == 1
                                      ? (widget.city
                                            ? 'Статистика города'
                                            : 'Статистика района')
                                      : 'Журнал рейсов',
                                  31,
                                ),
                              ),
                              IconButton(
                                tooltip: widget.city
                                    ? 'Добавить городской рейс'
                                    : 'Добавить районный рейс',
                                onPressed: () => _testEditor(
                                  context,
                                  'trip',
                                  initialType: tripType,
                                ),
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: gold,
                                  size: 33,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Expanded(
                            child: tab == 1
                                ? Column(
                                    children: [
                                      text(
                                        '${kg(total)} за месяц',
                                        28,
                                        color: gold,
                                      ),
                                      const SizedBox(height: 15),
                                      Expanded(
                                        child: CustomPaint(
                                          size: const Size(
                                            double.infinity,
                                            300,
                                          ),
                                          painter: _GasChart(
                                            daily,
                                            gold,
                                            line: true,
                                            labels: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      text(
                                        'Среднее за день с рейсами: ${kg(days.isEmpty ? 0 : total / days.length)}',
                                        20,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  )
                                : rows.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        text(
                                          widget.city
                                              ? 'В этом месяце городских рейсов нет'
                                              : 'В этом месяце районных рейсов нет',
                                          24,
                                          color: Colors.white60,
                                        ),
                                        const SizedBox(height: 20),
                                        TextButton(
                                          onPressed: () => _testEditor(
                                            context,
                                            'trip',
                                            initialType: tripType,
                                          ),
                                          child: text(
                                            '+ Добавить рейс',
                                            25,
                                            color: gold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : tab == 2
                                ? ListView(
                                    padding: EdgeInsets.zero,
                                    children: [
                                      for (final row in rows)
                                        record(
                                          row,
                                          b.recordDay(row),
                                          factor: 1.5,
                                        ),
                                    ],
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: days.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 7),
                                    itemBuilder: (c, i) {
                                      final date = days[i],
                                          entries = grouped[date]!,
                                          destinations = names(entries);
                                      return _GasTap(
                                        label:
                                            '${_detailDate(date)}, ${destinations.join(', ')}, ${kg(weight(entries))}',
                                        onTap: () => openDay(date),
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            minHeight: 73,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 13,
                                            vertical: 10,
                                          ),
                                          decoration: glass(),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 48,
                                                child: text(
                                                  '${date.day}'.padLeft(2, '0'),
                                                  32,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 117,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    text(
                                                      _garageMonths[date.month -
                                                          1],
                                                      19,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    text(
                                                      const [
                                                        'Пн',
                                                        'Вт',
                                                        'Ср',
                                                        'Чт',
                                                        'Пт',
                                                        'Сб',
                                                        'Вс',
                                                      ][date.weekday - 1],
                                                      16,
                                                      color: Colors.white54,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.location_on_outlined,
                                                color: blue,
                                                size: 34,
                                              ),
                                              const SizedBox(width: 15),
                                              Expanded(
                                                child: Text(
                                                  destinations.isEmpty
                                                      ? missingDirection
                                                      : destinations.join(', '),
                                                  style: const TextStyle(
                                                    color: white,
                                                    fontSize: 22,
                                                    height: 1.15,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              SizedBox(
                                                width: 155,
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: text(
                                                    kg(weight(entries)),
                                                    29,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Icon(
                                                Icons.chevron_right,
                                                color: white,
                                                size: 31,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
              return SingleChildScrollView(
                child: SizedBox(
                  width: box.maxWidth,
                  height: math.max(
                    box.maxHeight,
                    1536 * scale + safe + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _ExtendedArtwork(
                          asset: widget.city
                              ? 'assets/images/scenes/city_dashboard.png'
                              : 'assets/images/scenes/district_dashboard.png',
                          topInset: safe,
                        ),
                      ),
                      Positioned(
                        top: safe,
                        left: 0,
                        width: box.maxWidth,
                        height: 1536 * scale,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: MediaQuery.withClampedTextScaling(
                            minScaleFactor: 1,
                            maxScaleFactor: 1,
                            child: scene,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

class _SalaryDashboard extends StatefulWidget {
  final DateTime month;
  const _SalaryDashboard({required this.month});
  @override
  State<_SalaryDashboard> createState() => _SalaryDashboardState();
}

class _SalaryDashboardState extends State<_SalaryDashboard> {
  late DateTime month = DateTime(widget.month.year, widget.month.month);
  static const gold = Color(0xFFE0B16A), white = Color(0xFFE8EDEE);
  static const parts = [
    ('base_salary', 'Основной оклад'),
    ('weekend_pay', 'Выходные'),
    ('holiday_pay', 'Праздники'),
    ('paid_routes_pay', 'Платные рейсы'),
    ('city_pay', 'Городской вес'),
    ('region_pay', 'Районный вес'),
  ];
  Widget text(String s, double size, {Color color = white}) => Text(
    s,
    style: TextStyle(color: color, fontSize: size, height: 1.12),
  );
  String money(double n) => '${_fmtInt(n)} ₸';
  Widget fitted(String s, double size, {Color color = white}) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: text(s, size, color: color),
  );
  void days() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF101A21),
    builder: (sheet) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheet).height * .75,
        child: _TestLive(
          builder: (b) {
            final groups = <DateTime, List<Map<String, dynamic>>>{};
            for (final s in b.shifts) {
              final d = DateTime.parse(s['start'] as String);
              if (d.year == month.year && d.month == month.month)
                (groups[DateTime(d.year, d.month, d.day)] ??= []).add(s);
            }
            final dates = groups.keys.toList()..sort((a, z) => z.compareTo(a));
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: text('Зарплата по дням', 20)),
                      IconButton(
                        onPressed: () => Navigator.pop(sheet),
                        icon: const Icon(Icons.close, color: white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: dates.isEmpty
                      ? Center(child: text('В этом месяце смен нет', 16))
                      : ListView(
                          children: [
                            for (final date in dates)
                              ListTile(
                                title: text(_detailDate(date), 16),
                                trailing: text(
                                  money(
                                    b.statistics(month, day: date)['salary'] ??
                                        0,
                                  ),
                                  17,
                                  color: gold,
                                ),
                                onTap: () => _openDaySummary(sheet, date),
                              ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFF071017),
      body: _TestLive(
        builder: (b) {
          final stats = b.statistics(month);
          String val(String key, {String unit = '₸'}) => unit == '₸'
              ? money(stats[key] ?? 0)
              : '${_fmt1(stats[key] ?? 0)} $unit';
          return LayoutBuilder(
            builder: (context, box) {
              final scale = box.maxWidth / 864,
                  safe = MediaQuery.paddingOf(context).top;
              Widget at(double x, double y, double w, double h, Widget child) =>
                  Positioned(
                    left: x,
                    top: y,
                    width: w,
                    height: h,
                    child: child,
                  );
              Widget side(
                String title,
                String value,
                IconData icon,
                double angle,
              ) => Transform.rotate(
                angle: angle,
                child: Row(
                  children: [
                    Icon(icon, color: gold, size: 31),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          fitted(title, 21),
                          const SizedBox(height: 9),
                          SizedBox(height: 32, child: fitted(value, 30)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
              Widget tap(String label, VoidCallback action, Widget child) =>
                  _GasTap(label: label, onTap: action, child: child);
              final scene = SizedBox(
                width: 864,
                height: 1536,
                child: Stack(
                  children: [
                    at(
                      43,
                      40,
                      68,
                      60,
                      tap(
                        'Назад',
                        () => Navigator.pop(context),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xE511171B),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: const Color(0xFF6B695F)),
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: white,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                    at(
                      314,
                      40,
                      253,
                      60,
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: gold,
                            size: 44,
                          ),
                          const SizedBox(width: 17),
                          text('Зарплата', 40),
                        ],
                      ),
                    ),
                    at(
                      595,
                      40,
                      226,
                      60,
                      tap(
                        'Выбрать месяц',
                        pickMonth,
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xEB11171B),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFF6B695F)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              text(
                                '${_garageMonths[month.month - 1]} ${month.year}',
                                24,
                              ),
                              const Icon(
                                Icons.expand_more,
                                color: gold,
                                size: 27,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    at(
                      79,
                      196,
                      166,
                      74,
                      side(
                        'Основной оклад',
                        val('base_salary'),
                        Icons.toll_outlined,
                        .17,
                      ),
                    ),
                    at(
                      79,
                      309,
                      166,
                      70,
                      side(
                        'Выходные',
                        val('weekend_pay'),
                        Icons.calendar_month_outlined,
                        .15,
                      ),
                    ),
                    at(
                      79,
                      421,
                      166,
                      71,
                      side(
                        'Праздники',
                        val('holiday_pay'),
                        Icons.card_giftcard,
                        .12,
                      ),
                    ),
                    at(
                      624,
                      207,
                      171,
                      76,
                      side(
                        'Платные рейсы',
                        val('paid_routes_pay'),
                        Icons.local_shipping_outlined,
                        -.17,
                      ),
                    ),
                    at(
                      624,
                      321,
                      171,
                      76,
                      side(
                        'Отработано',
                        val('all_hours', unit: 'ч'),
                        Icons.access_time,
                        -.15,
                      ),
                    ),
                    at(
                      624,
                      438,
                      171,
                      70,
                      side(
                        'Норма',
                        val('norm_hours', unit: 'ч'),
                        Icons.bar_chart,
                        -.12,
                      ),
                    ),
                    at(
                      324,
                      285,
                      226,
                      34,
                      Center(
                        child: fitted('Заработано за месяц', 22, color: gold),
                      ),
                    ),
                    at(
                      315,
                      325,
                      240,
                      66,
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            val('salary'),
                            maxLines: 1,
                            style: const TextStyle(
                              color: gold,
                              fontSize: 55,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    at(
                      100,
                      816,
                      659,
                      46,
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            color: gold,
                            size: 33,
                          ),
                          const SizedBox(width: 22),
                          text('Состав зарплаты', 29),
                        ],
                      ),
                    ),
                    for (var i = 0; i < parts.length; i++)
                      at(
                        111,
                        872 + i * 43,
                        649,
                        36,
                        Row(
                          children: [
                            Expanded(child: text(parts[i].$2, 22)),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 220,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: fitted(val(parts[i].$1), 23),
                              ),
                            ),
                          ],
                        ),
                      ),
                    at(
                      130,
                      1160,
                      274,
                      63,
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: gold, size: 34),
                          const SizedBox(width: 30),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                text('Отработано', 20, color: Colors.white70),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: fitted(
                                    val('all_hours', unit: 'ч'),
                                    32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    at(
                      473,
                      1160,
                      272,
                      63,
                      Row(
                        children: [
                          const Icon(Icons.bar_chart, color: gold, size: 36),
                          const SizedBox(width: 30),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                text('Норма', 20, color: Colors.white70),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: fitted(
                                    val('norm_hours', unit: 'ч'),
                                    32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    at(
                      104,
                      1255,
                      661,
                      68,
                      tap(
                        'Посмотреть по дням',
                        days,
                        Row(
                          children: [
                            const SizedBox(width: 24),
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: gold,
                              size: 35,
                            ),
                            const SizedBox(width: 30),
                            Expanded(child: text('Посмотреть по дням', 25)),
                            const Icon(
                              Icons.chevron_right,
                              color: gold,
                              size: 38,
                            ),
                            const SizedBox(width: 18),
                          ],
                        ),
                      ),
                    ),
                    at(
                      487,
                      1347,
                      272,
                      53,
                      tap(
                        'Создать отчёт',
                        () => _openSalaryReport(context, month),
                        Row(
                          children: [
                            const Icon(Icons.bar_chart, color: gold, size: 35),
                            const SizedBox(width: 22),
                            Expanded(
                              child: text('Создать отчёт', 23, color: gold),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: gold,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
              return SingleChildScrollView(
                child: SizedBox(
                  width: box.maxWidth,
                  height: math.max(
                    box.maxHeight,
                    1536 * scale + safe + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _ExtendedArtwork(
                          asset: 'assets/images/scenes/salary_dashboard.png',
                          topInset: safe,
                        ),
                      ),
                      Positioned(
                        top: safe,
                        left: 0,
                        width: box.maxWidth,
                        height: 1536 * scale,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: MediaQuery.withClampedTextScaling(
                            minScaleFactor: 1,
                            maxScaleFactor: 1,
                            child: scene,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );

  Future<void> pickMonth() async {
    var year = month.year;
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: const Color(0xFF101A21),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) => SafeArea(
          child: SizedBox(
            height: 340,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: year > 2000
                          ? () => update(() => year--)
                          : null,
                      icon: const Icon(Icons.chevron_left, color: gold),
                    ),
                    Text(
                      '$year',
                      style: const TextStyle(color: white, fontSize: 20),
                    ),
                    IconButton(
                      onPressed: year < 2100
                          ? () => update(() => year++)
                          : null,
                      icon: const Icon(Icons.chevron_right, color: gold),
                    ),
                  ],
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    children: List.generate(
                      12,
                      (i) => TextButton(
                        onPressed: () =>
                            Navigator.pop(sheet, DateTime(year, i + 1)),
                        child: Text(
                          _garageMonths[i],
                          style: TextStyle(
                            color: year == month.year && i + 1 == month.month
                                ? gold
                                : white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => month = selected);
  }
}

void _openSalaryReport(BuildContext context, DateTime month) => Navigator.push(
  context,
  MaterialPageRoute<void>(builder: (_) => _SalaryReportPreview(month: month)),
);

class _SalaryReportPreview extends StatefulWidget {
  final DateTime month;
  const _SalaryReportPreview({required this.month});
  @override
  State<_SalaryReportPreview> createState() => _SalaryReportPreviewState();
}

class _SalaryReportPreviewState extends State<_SalaryReportPreview> {
  static const channel = MethodChannel('melnitsa/advance_image');
  dynamic _bytes;
  bool _loading = true, _sharing = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _render();
  }

  Future<void> _render() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final b = await TestStore.load();
      final month = widget.month;
      final stats = b.statistics(month);
      final shifts = b.shifts
          .where((s) => b.inMonth(s['start'] as String, month))
          .toList();
      final ids = shifts.map((s) => s['id']).toSet();
      final paid = b.records
          .where(
            (r) =>
                ids.contains(r['shiftId']) &&
                r['kind'] == 'trip' &&
                r['isPaid'] == true,
          )
          .length;
      final weekends = shifts
          .map((s) => DateTime.parse(s['start'] as String))
          .where(
            (d) => shifts.any(
              (s) =>
                  TestState.dayKey(DateTime.parse(s['start'] as String)) ==
                      TestState.dayKey(d) &&
                  b.weekendShift(s),
            ),
          )
          .map(TestState.dayKey)
          .toSet()
          .length;
      String weight(double value) => '${_fmt1(value)} кг';
      final data = await channel.invokeMethod<dynamic>('renderSalary', {
        'month': '${_garageMonths[month.month - 1]} ${month.year}',
        'rows': [
          ['Городской вес', weight(stats['city_kg'] ?? 0)],
          ['Районный вес', weight(stats['region_kg'] ?? 0)],
          ['Платные поездки', '$paid'],
          ['Отработано выходных', '$weekends'],
        ],
      });
      if (mounted)
        setState(() {
          _bytes = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Не удалось создать отчёт';
          _loading = false;
        });
    }
  }

  Future<void> _share() async {
    if (_bytes == null || _sharing) return;
    setState(() => _sharing = true);
    try {
      await channel.invokeMethod<void>('shareSalary', {'bytes': _bytes});
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть отправку. Попробуйте ещё раз.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_sharing,
    child: Scaffold(
      backgroundColor: const Color(0xFF111619),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111619),
        foregroundColor: Colors.white,
        title: const Text('Отчёт для сверки'),
        automaticallyImplyLeading: !_sharing,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.white),
                          ),
                          TextButton(
                            onPressed: _render,
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    )
                  : InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.memory(_bytes),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton.icon(
                onPressed: _loading || _sharing || _bytes == null
                    ? null
                    : _share,
                style: TextButton.styleFrom(
                  foregroundColor: _CinematicMore.gold,
                ),
                icon: const Icon(Icons.share_outlined),
                label: Text(_sharing ? 'Подготовка…' : 'Поделиться картинкой'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
