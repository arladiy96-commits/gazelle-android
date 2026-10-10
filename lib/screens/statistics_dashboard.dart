part of 'app_shell.dart';

class _MillStatistics extends StatefulWidget {
  final AppSession session;
  final VoidCallback? onHome;
  const _MillStatistics({required this.session, this.onHome});
  @override
  State<_MillStatistics> createState() => _MillStatisticsState();
}

class _StatsDay {
  final DateTime date;
  final double city, region, km, salary;
  final int trips;
  const _StatsDay(
    this.date,
    this.city,
    this.region,
    this.km,
    this.salary,
    this.trips,
  );
  double get kg => city + region;
  bool get active => kg != 0 || km != 0 || salary != 0 || trips != 0;
  double value(int i) => switch (i) {
    0 => kg,
    1 => trips.toDouble(),
    2 => km,
    3 => salary,
    _ => km > 0 ? kg / km : 0,
  };
}

class _MillStatisticsState extends State<_MillStatistics> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  int period = 0, metric = 0;
  bool onlyActive = false;
  DateTimeRange? custom;
  static const gold = Color(0xFFE4AB50);
  static const names = [
    'Тоннаж',
    'Рейсы',
    'Пробег',
    'Зарплата',
    'Эффективность',
  ];
  static const units = ['кг', 'рейсов', 'км', '₸', 'кг/км'];
  DateTimeRange get range => period == 2 && custom != null
      ? custom!
      : DateTimeRange(
          start: DateTime(month.year, month.month - (period == 1 ? 2 : 0)),
          end: DateTime(month.year, month.month + 1, 0),
        );
  String date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
  String get periodLabel => period == 0
      ? '${_garageMonths[month.month - 1]} ${month.year} г.'
      : '${date(range.start)}.${range.start.year} — ${date(range.end)}.${range.end.year}';
  List<_StatsDay> data(TestState b, DateTimeRange r) {
    final out = <_StatsDay>[];
    final factors = <String, double>{};
    for (
      var d = r.start;
      !d.isAfter(r.end);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      final key = '${d.year}-${d.month}';
      final factor = factors.putIfAbsent(key, () {
        var sum = 0.0;
        for (var i = 1; i <= DateTime(d.year, d.month + 1, 0).day; i++)
          sum +=
              b.statistics(
                d,
                day: DateTime(d.year, d.month, i),
              )['base_salary'] ??
              0;
        return sum == 0 ? 1 : (b.statistics(d)['base_salary'] ?? 0) / sum;
      });
      final s = b.statistics(d, day: d);
      final trips = b.records
          .where(
            (e) =>
                e['kind'] == 'trip' &&
                TestState.dayKey(b.recordDay(e)) == TestState.dayKey(d),
          )
          .length;
      out.add(
        _StatsDay(
          d,
          s['city_kg'] ?? 0,
          s['region_kg'] ?? 0,
          _summaryMileage(b, d),
          (s['salary'] ?? 0) - (s['base_salary'] ?? 0) * (1 - factor),
          trips,
        ),
      );
    }
    return out;
  }

  double total(List<_StatsDay> rows, int i) {
    if (i == 4) {
      final km = rows.fold<double>(0, (s, d) => s + d.km);
      return km == 0 ? 0 : rows.fold<double>(0, (s, d) => s + d.kg) / km;
    }
    return rows.fold<double>(0, (s, d) => s + d.value(i));
  }

  Future<void> pickMonth() async {
    var year = month.year;
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: const Color(0xFF111A20),
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SizedBox(
            height: 300,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => update(() => year--),
                      icon: const Icon(Icons.chevron_left, color: gold),
                    ),
                    Text(
                      '$year',
                      style: const TextStyle(color: Colors.white, fontSize: 19),
                    ),
                    IconButton(
                      onPressed: () => update(() => year++),
                      icon: const Icon(Icons.chevron_right, color: gold),
                    ),
                  ],
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    children: [
                      for (var m = 1; m <= 12; m++)
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(sheet, DateTime(year, m)),
                          child: Text(
                            _garageMonths[m - 1],
                            style: const TextStyle(color: gold),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted)
      setState(() {
        month = selected;
        if (period == 2) period = 0;
      });
  }

  Future<void> setPeriod(int i) async {
    if (i != 2) {
      setState(() => period = i);
      return;
    }
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: range,
      helpText: 'Выберите период',
      saveText: 'Готово',
    );
    if (r != null && mounted)
      setState(() {
        custom = r;
        period = 2;
      });
  }

  Future<void> _openGeneralReport() async {
    final owner = AccountScope.capture();
    final choice = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF101A21),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Период общего отчёта',
                style: TextStyle(fontSize: 18),
              ),
            ),
            for (final entry in const {
              0: 'Выбранный в статистике период',
              1: 'За месяц',
              2: 'За один день',
              3: 'Произвольный период',
            }.entries)
              ListTile(
                title: Text(entry.value),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(c, entry.key),
              ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null || !owner.valid) return;
    var selected = range;
    if (choice == 1 || choice == 2) {
      final d = await showDatePicker(
        context: context,
        initialDate: month,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        helpText: choice == 1
            ? 'Выберите любой день нужного месяца'
            : 'День отчёта',
      );
      if (!mounted || d == null || !owner.valid) return;
      selected = choice == 1
          ? DateTimeRange(
              start: DateTime(d.year, d.month),
              end: DateTime(d.year, d.month + 1, 0),
            )
          : DateTimeRange(start: d, end: d);
    } else if (choice == 3) {
      final r = await showDateRangePicker(
        context: context,
        initialDateRange: range,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        helpText: 'Период отчёта',
        saveText: 'Готово',
      );
      if (!mounted || r == null || !owner.valid) return;
      selected = r;
    }
    if (selected.duration.inDays > 366) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите период не больше года')),
      );
      return;
    }
    try {
      final state = await owner.bind(() => TestStore.load());
      if (!mounted || !owner.valid) return;
      final daily = data(state, selected);
      final payload = _generalReportPayload(
        state,
        daily,
        selected,
        (SessionService.current ?? widget.session).displayName,
      );
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => _GeneralReportPreview(payload: payload, owner: owner),
        ),
      );
    } catch (_) {
      if (mounted && owner.valid)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось подготовить отчёт. Попробуйте ещё раз.'),
          ),
        );
    }
  }

  void openDay(TestState b, _StatsDay d) {
    _openDaySummary(context, d.date);
  }

  Widget panel(Widget child, {bool light = false}) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF86603C), width: .8),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: light
            ? const [Color(0xEB10171C), Color(0xA010171C)]
            : const [Color(0xF21A2024), Color(0xF0080F14)],
      ),
    ),
    child: child,
  );
  Widget chip(String label, bool selected, VoidCallback tap) => Padding(
    padding: const EdgeInsets.only(right: 5),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: selected ? const Color(0xAA5D3B12) : const Color(0xCC10171C),
            border: Border.all(
              color: selected ? gold : const Color(0xFF694829),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? gold : const Color(0xFFB4BABE),
              fontSize: 11,
            ),
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      _TestLive(
        builder: (b) {
          final rows = data(b, range);
          final shown = rows.where((d) => !onlyActive || d.active).toList();
          final previous = period == 2
              ? DateTimeRange(
                  start: DateTime(
                    range.start.year,
                    range.start.month,
                    range.start.day - rows.length,
                  ),
                  end: DateTime(
                    range.start.year,
                    range.start.month,
                    range.start.day - 1,
                  ),
                )
              : DateTimeRange(
                  start: DateTime(
                    range.start.year,
                    range.start.month - (period == 1 ? 3 : 1),
                  ),
                  end: DateTime(range.start.year, range.start.month, 0),
                );
          final before = data(b, previous);
          final hasBefore = before.any((d) => d.active);
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed:
                        widget.onHome ?? () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back, color: gold),
                  ),
                  const Expanded(
                    child: Text(
                      'Статистика',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: pickMonth,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: gold,
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${_garageMonths[month.month - 1]} ${month.year}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        const Icon(Icons.expand_more, color: gold, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ПЕРИОД',
                      style: TextStyle(
                        color: Color(0xFFB5B5AE),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      periodLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          chip(
                            const ['Месяц', '3 месяца', 'Свой'][i],
                            period == i,
                            () => setPeriod(i),
                          ),
                      ],
                    ),
                  ],
                ),
                light: true,
              ),
              panel(
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined, color: gold),
                  title: const Text(
                    'Открыть общий отчёт',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Работа, тоннаж и заработок · PDF / PNG',
                    style: TextStyle(color: Color(0xFFADB7BE), fontSize: 11),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: gold),
                  onTap: _openGeneralReport,
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      chip(
                        names[i],
                        metric == i,
                        () => setState(() => metric = i),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              panel(
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${names[metric]}, ${units[metric]}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${_fmt1(total(rows, metric))} ${units[metric]}',
                          style: const TextStyle(
                            color: gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 145,
                      width: double.infinity,
                      child: LayoutBuilder(
                        builder: (context, box) => GestureDetector(
                          onTapUp: (tap) {
                            final i =
                                ((tap.localPosition.dx - 35) /
                                        (box.maxWidth - 45) *
                                        (rows.length - 1))
                                    .round()
                                    .clamp(0, rows.length - 1);
                            openDay(b, rows[i]);
                          },
                          child: CustomPaint(
                            painter: _StatsLine(
                              rows.map((d) => d.value(metric)).toList(),
                              rows.map((d) => date(d.date)).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (metric == 4)
                      const Text(
                        'Эффективность — перевезённые кг на 1 км',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                  ],
                ),
              ),
              panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Сравнение с предыдущим периодом',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    if (!hasBefore)
                      const Text(
                        'За предыдущий период данных нет',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      )
                    else
                      Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final prev = total(before, i),
                                      now = total(rows, i);
                                  final delta = now - prev;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        names[i],
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        prev == 0
                                            ? '—'
                                            : '${delta >= 0 ? '+' : ''}${_fmt1(delta / prev * 100)}%',
                                        style: TextStyle(
                                          color: delta >= 0
                                              ? const Color(0xFF7CCF91)
                                              : const Color(0xFF57ADD2),
                                          fontSize: 19,
                                        ),
                                      ),
                                      Text(
                                        '${delta >= 0 ? '+' : ''}${_fmt1(delta)} ${units[i]}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                light: true,
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Ключевые итоги',
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == 3 ? 0 : 5),
                        child: panel(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                const [
                                  Icons.scale_outlined,
                                  Icons.local_shipping_outlined,
                                  Icons.route_outlined,
                                  Icons.payments_outlined,
                                ][i],
                                color: gold,
                                size: 20,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                names[i],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _fmt1(total(rows, i)),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                units[i],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              panel(
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: gold,
                          size: 19,
                        ),
                        const SizedBox(width: 7),
                        const Expanded(
                          child: Text(
                            'Детализация по дням',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        PopupMenuButton<bool>(
                          initialValue: onlyActive,
                          onSelected: (v) => setState(() => onlyActive = v),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: false, child: Text('Все дни')),
                            PopupMenuItem(
                              value: true,
                              child: Text('С записями'),
                            ),
                          ],
                          child: Row(
                            children: [
                              Text(
                                onlyActive ? 'С записями' : 'Все дни',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                              const Icon(
                                Icons.expand_more,
                                color: gold,
                                size: 17,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    tableRow([
                      'Дата',
                      'Город, кг',
                      'Район, кг',
                      'Км',
                      '₸',
                    ], header: true),
                    if (shown.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Записей за период нет',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    for (final d in shown)
                      InkWell(
                        onTap: () => openDay(b, d),
                        child: tableRow([
                          date(d.date),
                          _fmt1(d.city),
                          _fmt1(d.region),
                          _fmt1(d.km),
                          _fmt1(d.salary),
                        ], weekend: d.date.weekday >= 6),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ],
  );
  Widget tableRow(
    List<String> cells, {
    bool header = false,
    bool weekend = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFF293238), width: .5)),
    ),
    child: Row(
      children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            child: Text(
              cells[i],
              textAlign: i == 0 ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                color: header
                    ? Colors.grey
                    : i == 0 && weekend
                    ? const Color(0xFFD78576)
                    : const Color(0xFFD5D9DB),
                fontSize: header ? 9 : 10,
              ),
            ),
          ),
        SizedBox(
          width: 12,
          child: header
              ? null
              : const Icon(Icons.chevron_right, size: 12, color: gold),
        ),
      ],
    ),
  );
}

class _StatsLine extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  const _StatsLine(this.values, this.labels);
  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFE9AC50);
    final rect = Rect.fromLTWH(
      35,
      8,
      math.max(1, size.width - 45),
      size.height - 29,
    );
    final maximum = math.max(1.0, values.fold<double>(0, math.max) * 1.15);
    void label(String t, Offset p) {
      final painter = TextPainter(
        text: TextSpan(
          text: t,
          style: const TextStyle(color: Color(0xFF92999D), fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, p);
    }

    for (var i = 0; i < 5; i++) {
      final y = rect.bottom - rect.height * i / 4;
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y),
        Paint()
          ..color = const Color(0xFF263037)
          ..strokeWidth = .5,
      );
      label(_fmt1(maximum * i / 4), Offset(0, y - 4));
    }
    if (values.isEmpty) return;
    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final p = Offset(
        rect.left + rect.width * i / math.max(1, values.length - 1),
        rect.bottom - rect.height * values[i] / maximum,
      );
      points.add(p);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    final fill = Path.from(path)
      ..lineTo(points.last.dx, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x665F401A), Color(0x035F401A)],
        ).createShader(rect),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = gold.withOpacity(.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    final step = math.max(1, (values.length / 7).ceil());
    for (var i = 0; i < points.length; i++) {
      if (values.length <= 31 || i % step == 0) {
        canvas.drawCircle(points[i], 2.3, Paint()..color = gold);
        canvas.drawCircle(
          points[i],
          1.2,
          Paint()..color = const Color(0xFF10171C),
        );
      }
      if (i % step == 0)
        label(labels[i], Offset(points[i].dx - 8, rect.bottom + 7));
    }
  }

  @override
  bool shouldRepaint(covariant _StatsLine old) =>
      old.values != values || old.labels != labels;
}

class _MillStatisticsRoute extends StatelessWidget {
  final AppSession session;
  const _MillStatisticsRoute({required this.session});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Positioned.fill(
          child: _ExtendedArtwork(
            asset: 'assets/images/scenes/statistics_dashboard.png',
            topInset: MediaQuery.paddingOf(context).top,
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(child: _MillStatistics(session: session)),
      ],
    ),
    bottomNavigationBar: _BottomNavigation(
      index: 3,
      items: const [
        _NavItem(
          label: 'Главная',
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
        ),
        _NavItem(
          label: 'Работа',
          icon: Icons.local_shipping_outlined,
          activeIcon: Icons.local_shipping_rounded,
        ),
        _NavItem(label: 'Добавить', icon: Icons.add, activeIcon: Icons.add),
        _NavItem(
          label: 'Статистика',
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart_rounded,
        ),
        _NavItem(
          label: 'Ещё',
          icon: Icons.grid_view_outlined,
          activeIcon: Icons.grid_view_rounded,
        ),
      ],
      onChanged: (i) {
        if (i == 3) return;
        if (i == 4) {
          _openHomeMenu(context, session);
          return;
        }
        _CinematicMore(session: session).navigate(context, i);
      },
      onLongPressLogo: () {},
    ),
  );
}

String _reportNumber(double value, [int decimals = 2]) {
  final parts = value.toStringAsFixed(decimals).split('.');
  parts[0] = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]} ',
  );
  return parts.join(',');
}

String _reportDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

Map<String, Object> _generalReportPayload(
  TestState state,
  List<_StatsDay> days,
  DateTimeRange range,
  String name,
) {
  final totals = <String, double>{};
  final rows = <List<String>>[];
  var shiftCount = 0,
      openCount = 0,
      missingKm = 0,
      missingHours = 0,
      trips = 0,
      paidTrips = 0;
  var city = 0.0, region = 0.0, km = 0.0, hours = 0.0;
  var salaryCents = 0;
  final groups = <String, List<Map<String, dynamic>>>{};
  for (final shift in state.shifts) {
    final key = TestState.dayKey(DateTime.parse(shift['start'] as String));
    groups.putIfAbsent(key, () => []).add(shift);
  }
  for (final day in days) {
    final shifts = groups[TestState.dayKey(day.date)] ?? [];
    if (shifts.isEmpty && !day.active) continue;
    final values = state.statistics(day.date, day: day.date);
    final isOpen = shifts.any((s) => s['end'] == null);
    final noKm = shifts.any((s) => !state.hasRecordedMileage(s));
    final noHours = shifts.any((s) => s['hoursWorked'] is! num);
    shiftCount += shifts.length;
    openCount += shifts.where((s) => s['end'] == null).length;
    missingKm += shifts.where((s) => !state.hasRecordedMileage(s)).length;
    missingHours += shifts.where((s) => s['hoursWorked'] is! num).length;
    for (final shift in shifts) {
      paidTrips += state
          .forShift(shift['id'] as String)
          .where((e) => e['kind'] == 'trip' && e['isPaid'] == true)
          .length;
    }
    trips += day.trips;
    city += day.city;
    region += day.region;
    km += day.km;
    final dayHours = values['all_hours'] ?? 0;
    hours += dayHours;
    final cents = (day.salary * 100).round();
    salaryCents += cents;
    // Preserve the same base-pay allocation as the statistics screen.
    values['base_salary'] =
        (values['base_salary'] ?? 0) + day.salary - (values['salary'] ?? 0);
    for (final key in [
      'base_salary',
      'city_pay',
      'region_pay',
      'paid_routes_pay',
      'weekend_pay',
      'holiday_pay',
      'gas',
      'petrol',
    ]) {
      totals[key] = (totals[key] ?? 0) + (values[key] ?? 0);
    }
    rows.add([
      '${_reportDate(day.date)}${isOpen ? '*' : ''}',
      '${_reportNumber(dayHours)}${noHours ? '*' : ''}',
      '${day.trips}',
      _reportNumber(day.city / 1000, 3),
      _reportNumber(day.region / 1000, 3),
      '${_reportNumber(day.km)}${noKm ? '*' : ''}',
      _reportNumber(cents / 100),
    ]);
  }
  String n(String key) => _reportNumber(totals[key] ?? 0);
  return {
    'name': name,
    'period': '${_reportDate(range.start)} — ${_reportDate(range.end)}',
    'created': 'Сформирован ${_reportDate(DateTime.now())}',
    'summary': <List<String>>[
      ['Смен / незавершённых', '$shiftCount / $openCount'],
      ['Отработано часов (внесено)', _reportNumber(hours)],
      ['Рейсов / платных направлений', '$trips / $paidTrips'],
      ['Город, т', _reportNumber(city / 1000, 3)],
      ['Район, т', _reportNumber(region / 1000, 3)],
      ['Всего перевезено, т', _reportNumber((city + region) / 1000, 3)],
      ['Пробег (внесено), км', _reportNumber(km)],
      ['Получено газа, л', n('gas')],
      ['Получено бензина, л', n('petrol')],
    ],
    'pay': <List<String>>[
      ['Основная оплата', n('base_salary')],
      ['За тоннаж города', n('city_pay')],
      ['За тоннаж района', n('region_pay')],
      ['Платные направления', n('paid_routes_pay')],
      ['Выходные', n('weekend_pay')],
      ['Праздничные', n('holiday_pay')],
      ['Всего начислено, ₸', _reportNumber(salaryCents / 100)],
    ],
    'rows': rows,
    'total': [
      'ИТОГО',
      _reportNumber(hours),
      '$trips',
      _reportNumber(city / 1000, 3),
      _reportNumber(region / 1000, 3),
      _reportNumber(km),
      _reportNumber(salaryCents / 100),
    ],
    'notes': <String>[
      if (rows.isEmpty) 'За выбранный период записей нет.',
      if (openCount > 0)
        '* Незавершённых смен: $openCount. Итоги предварительные.',
      if (missingHours > 0)
        '* Часы не внесены в $missingHours сменах; указана известная сумма.',
      if (missingKm > 0)
        '* Пробег не внесён в $missingKm сменах; указана известная сумма.',
      'Тоннаж: 1 т = 1 000 кг. Топливо: получено, а не израсходовано.',
      'Удержания и выплаты не учтены. «Начислено» не означает «К выплате».',
      'День смены определяется датой её начала. Показаны дни с записями.',
      'Суммы округлены до 0,01 ₸; возможна разница округления составляющих.',
    ],
  };
}

class _GeneralReportPreview extends StatefulWidget {
  final Map<String, Object> payload;
  final AccountToken owner;
  const _GeneralReportPreview({required this.payload, required this.owner});
  @override
  State<_GeneralReportPreview> createState() => _GeneralReportPreviewState();
}

class _GeneralReportPreviewState extends State<_GeneralReportPreview> {
  static const channel = MethodChannel('melnitsa/advance_image');
  dynamic _image;
  String? _error;
  bool _busy = false, _detail = true;
  int _page = 0;
  int get _pages =>
      1 + (_detail ? ((widget.payload['rows'] as List).length + 24) ~/ 25 : 0);
  Map<String, Object> get _args => {
    ...widget.payload,
    'detail': _detail,
    'page': _page,
  };
  @override
  void initState() {
    super.initState();
    _render();
  }

  Future<void> _render() async {
    if (!widget.owner.valid) return;
    setState(() {
      _busy = true;
      _error = null;
      _image = null;
    });
    try {
      final bytes = await channel.invokeMethod<dynamic>('renderGeneral', _args);
      if (mounted && widget.owner.valid) setState(() => _image = bytes);
    } catch (_) {
      if (mounted)
        setState(
          () => _error = 'Не удалось создать бланк. Попробуйте ещё раз.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(bool pdf) async {
    if (_busy || !widget.owner.valid) return;
    setState(() => _busy = true);
    try {
      final bytes = pdf
          ? await channel.invokeMethod<dynamic>('renderGeneralPdf', _args)
          : _image;
      if (!mounted || !widget.owner.valid) return;
      final saved = await channel.invokeMethod<bool>('save', {
        'bytes': bytes,
        'kind': pdf ? 'generalPdf' : 'generalPng',
      });
      if (mounted && widget.owner.valid && saved == true)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pdf ? 'PDF сохранён' : 'Страница сохранена')),
        );
    } catch (_) {
      if (mounted && widget.owner.valid)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось сохранить. Попробуйте ещё раз.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      backgroundColor: const Color(0xFF0B151C),
      appBar: AppBar(
        title: const Text('Общий отчёт', style: TextStyle(fontSize: 20)),
        backgroundColor: const Color(0xFF101A21),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Подробный бланк'),
              subtitle: const Text('Итоги и таблица по дням'),
              value: _detail,
              onChanged: _busy
                  ? null
                  : (v) {
                      setState(() {
                        _detail = v;
                        _page = 0;
                      });
                      _render();
                    },
            ),
            Expanded(
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: TextButton(
                        onPressed: _render,
                        child: Text('$_error\nПовторить'),
                      ),
                    )
                  : _image == null
                  ? const SizedBox.shrink()
                  : InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 5,
                      child: Center(
                        child: Image.memory(_image, fit: BoxFit.contain),
                      ),
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _busy || _page == 0
                      ? null
                      : () {
                          _page--;
                          _render();
                        },
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Страница ${_page + 1} из $_pages'),
                IconButton(
                  onPressed: _busy || _page + 1 >= _pages
                      ? null
                      : () {
                          _page++;
                          _render();
                        },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _busy || _image == null
                        ? null
                        : () => _save(true),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Сохранить PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy || _image == null
                        ? null
                        : () => _save(false),
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Страница PNG'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
