part of 'app_shell.dart';

void _openGarageSection(BuildContext context, String section, String login) =>
    Navigator.of(context).push<void>(
      _SceneRoute(
        builder: (_) => section == 'Направления'
            ? const _DirectionsScreen()
            : _GarageSection(section: section, login: login),
      ),
    );

class _GarageSection extends StatefulWidget {
  final String section, login;
  const _GarageSection({required this.section, required this.login});
  @override
  State<_GarageSection> createState() => _GarageSectionState();
}

class _GarageSectionState extends State<_GarageSection> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  ActivityBook? _book;
  _HomeMonthData? _total;
  TestPreferences? _prefs;
  String _filter = 'Все';
  String? _error;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _homeDataRevision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _request++;
    _homeDataRevision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final id = ++_request;
    try {
      final p = await TestPreferences.getInstance();
      final b = await ActivityRepository.load(_month);
      final t = await _HomeMonthData.load(_month);
      if (mounted && id == _request)
        setState(() {
          _prefs = p;
          _book = b;
          _total = t;
          _error = null;
        });
    } catch (_) {
      if (mounted && id == _request)
        setState(() => _error = 'Не удалось загрузить записи');
    }
  }

  void _move(int n) {
    setState(() {
      _month = DateTime(_month.year, _month.month + n);
      _book = null;
    });
    _load();
  }

  void _day(DateTime d) =>
      Navigator.of(context)
          .push<void>(_SceneRoute(builder: (_) => _DayDetails(date: d)));
  @override
  Widget build(BuildContext context) => _DetailFrame(
    title: widget.section,
    showHero: false,
    children: [
      if (widget.section != 'Документы')
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _move(-1),
              tooltip: 'Предыдущий месяц',
              icon: const Icon(Icons.chevron_left, color: _amber),
            ),
            _dt('${_garageMonths[_month.month - 1]} ${_month.year}', size: 15),
            IconButton(
              onPressed: () => _move(1),
              tooltip: 'Следующий месяц',
              icon: const Icon(Icons.chevron_right, color: _amber),
            ),
          ],
        ),
      _SceneSpace(
        scene: _sceneFor(widget.section),
        controlsHeight: widget.section == 'Документы' ? 48 : 108,
      ),
      if (_error != null) ...[
        _DetailGlass(child: _dt(_error!)),
        _detailButton('Повторить', _load),
      ] else if (_book == null)
        const Center(child: CircularProgressIndicator(color: _amber))
      else if (widget.section == 'Документы')
        ..._documents()
      else if (widget.section == 'Статистика')
        ..._statistics()
      else if (widget.section == 'Направления')
        ..._directions()
      else
        ..._history(),
    ],
  );
  List<Widget> _history() {
    final dates = <DateTime>{
      for (final e in _book!.entries)
        DateTime(e.date.year, e.date.month, e.date.day),
    };
    for (int d = 1; d <= DateTime(_month.year, _month.month + 1, 0).day; d++) {
      final prefix = 'home_day_${_month.year}_${_month.month}_${d}_';
      if (_prefs!.getKeys().any((k) => k.startsWith(prefix)))
        dates.add(DateTime(_month.year, _month.month, d));
    }
    final sorted = dates.toList()..sort((a, b) => b.compareTo(a));
    return [
      _DetailGlass(
        accent: true,
        child: Row(
          children: [
            Expanded(
              child: _dt('Дней с записями', color: const Color(0xFFADC0CC)),
            ),
            _dt('${sorted.length}', size: 24),
          ],
        ),
      ),
      _dt('История по дням', size: 16),
      const SizedBox(height: 12),
      _DetailGlass(
        child: sorted.isEmpty
            ? _dt(
                'Записей за месяц пока нет. Добавленные рейсы и заправки появятся здесь.',
              )
            : Column(
                children: _separated([
                  for (final d in sorted)
                    _detailRow(
                      _detailDate(d),
                      '',
                      subtitle: _summary(d),
                      onTap: () => _day(d),
                      color: d.weekday >= 6 ? const Color(0xFFFFAA91) : null,
                    ),
                ]),
              ),
      ),
    ];
  }

  String _summary(DateTime d) {
    final rows = _book!.onDay(d);
    final trips = rows.where((e) => e.kind == 'trip').length;
    final fuels = rows.where((e) => e.kind == 'fuel').length;
    return 'Рейсов: $trips · Заправок: $fuels';
  }

  List<Widget> _statistics() {
    final t = _total!;
    return [
      _DetailGlass(
        accent: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dt('Начислено за месяц', color: const Color(0xFFADC0CC)),
            const SizedBox(height: 8),
            _detailRow(
              'Зарплата',
              '${_fmtInt(t.salary)} ₸',
              onTap: () => _openMetricDetails(context, 'Зарплата', _month),
            ),
          ],
        ),
      ),
      _DetailGlass(
        child: Column(
          children: _separated([
            _detailRow(
              'Город',
              '${_fmt1(t.city)} т',
              onTap: () => _openMetricDetails(context, 'Город', _month),
            ),
            _detailRow(
              'Район',
              '${_fmt1(t.region)} т',
              onTap: () => _openMetricDetails(context, 'Район', _month),
            ),
            _detailRow(
              'Пробег',
              '${_fmtInt(t.mileage)} км',
              onTap: () => _openMetricDetails(context, 'Пробег', _month),
            ),
            _detailRow(
              'Газ',
              '${_fmt1(t.gas)} л',
              onTap: () => _openMetricDetails(context, 'Газ', _month),
            ),
            _detailRow(
              'Бензин',
              '${_fmt1(t.petrol)} л',
              onTap: () => _openMetricDetails(context, 'Бензин', _month),
            ),
          ]),
        ),
      ),
      _TonnageChart(book: _book!, month: _month),
      _dt('Распределение тоннажа', size: 16),
      const SizedBox(height: 12),
      _DetailGlass(
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  if (t.city > 0)
                    Expanded(
                      flex: math.max(1, (t.city * 100).round()),
                      child: Container(height: 8, color: _amber),
                    ),
                  if (t.region > 0)
                    Expanded(
                      flex: math.max(1, (t.region * 100).round()),
                      child: Container(height: 8, color: _ice),
                    ),
                  if (t.city <= 0 && t.region <= 0)
                    Expanded(
                      child: Container(
                        height: 8,
                        color: const Color(0xFF33444D),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _dt('Город', color: _amber, size: 13),
                _dt('Район', color: _ice, size: 13),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _directions() {
    final rows = _book!.entries
        .where(
          (e) => e.kind == 'trip' && (_filter == 'Все' || e.type == _filter),
        )
        .toList();
    final names =
        rows
            .map((e) => e.direction.isEmpty ? 'Без направления' : e.direction)
            .toSet()
            .toList()
          ..sort();
    return [
      _QuickSegment(
        values: const ['Все', 'Город', 'Район'],
        selected: _filter,
        onChanged: (v) => setState(() => _filter = v),
      ),
      const SizedBox(height: 16),
      _dt(
        'Направления из журнала рейсов',
        size: 13,
        color: const Color(0xFFADC0CC),
      ),
      const SizedBox(height: 12),
      _DetailGlass(
        child: names.isEmpty
            ? _dt('Добавьте рейс через «+», и его направление появится здесь.')
            : Column(
                children: _separated([
                  for (final name in names)
                    _detailRow(
                      name,
                      '${_fmt1(rows.where((e) => (e.direction.isEmpty ? 'Без направления' : e.direction) == name).fold<double>(0, (s, e) => s + e.amount))} т',
                      subtitle:
                          'Рейсов: ${rows.where((e) => (e.direction.isEmpty ? 'Без направления' : e.direction) == name).length}',
                      onTap: () => _direction(name, rows),
                    ),
                ]),
              ),
      ),
    ];
  }

  void _direction(String name, List<ActivityEntry> rows) {
    final selected =
        rows
            .where(
              (e) =>
                  (e.direction.isEmpty ? 'Без направления' : e.direction) ==
                  name,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    Navigator.of(context).push<void>(
      _SceneRoute(
        builder: (_) => _DetailFrame(
          title: name,
          scene: _Scene.cargo,
          children: [
            _DetailGlass(
              child: Column(
                children: _separated([
                  for (final e in selected)
                    _detailRow(
                      _detailDate(e.date),
                      '${_fmt1(e.amount)} т',
                      subtitle: '${e.type} · ${_detailTime(e.date)}',
                      onTap: () => _day(e.date),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _docKey(String name) => 'garage_document_${widget.login}_$name';
  List<Widget> _documents() => [
    _DetailGlass(
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dt('Документы автомобиля', size: 17),
          const SizedBox(height: 6),
          _dt(
            'Сроки действия документов',
            size: 13,
            color: const Color(0xFFADC0CC),
          ),
        ],
      ),
    ),
    for (final name in const [
      'Страховка',
      'Техосмотр',
      'Водительское удостоверение',
      'Другое',
    ])
      _DetailGlass(
        child: _detailRow(
          name,
          '',
          subtitle: _docStatus(name),
          onTap: () => _editDocument(name),
        ),
      ),
  ];
  String _docStatus(String name) {
    final d = DateTime.tryParse(_prefs!.getString(_docKey(name)) ?? '');
    if (d == null) return 'Указать срок действия';
    final now = DateTime.now();
    final days = d.difference(DateTime(now.year, now.month, now.day)).inDays;
    return '${_detailDate(d)} ${d.year} · ${days < 0
        ? 'Срок истёк'
        : days == 0
        ? 'Истекает сегодня'
        : 'Осталось $days дн.'}';
  }

  Future<void> _editDocument(String name) async {
    final old = DateTime.tryParse(_prefs!.getString(_docKey(name)) ?? '');
    if (old != null) {
      final choice = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (c) => _QuickEntryShell(
          title: name,
          icon: Icons.description_outlined,
          child: Column(
            children: [
              _detailButton('Изменить срок', () => Navigator.pop(c, 'edit')),
              _detailButton('Удалить срок', () => Navigator.pop(c, 'delete')),
            ],
          ),
        ),
      );
      if (!mounted || choice == null) return;
      if (choice == 'delete') {
        await _testRun(context, () async {
          await _prefs!.remove(_docKey(name));
        });
        return;
      }
    }
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: old ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _amber,
            surface: Color(0xFF0B1A22),
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    try {
      if (!await _prefs!.setString(_docKey(name), date.toIso8601String()))
        throw StateError('save');
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Срок не сохранён. Повторите попытку.')),
        );
    }
  }
}
