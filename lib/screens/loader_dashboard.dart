part of 'app_shell.dart';

const _loaderGold = Color(0xFFC7A568);
const _loaderMuted = Color(0xFFAAB7BF);
String _loaderMoney(int minor) {
  final parts = (minor / 100).toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]} ',
  );
  return '$whole${parts[1] == '00' ? '' : ',${parts[1]}'} ₸';
}

String _loaderDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
String _loaderHours(int minutes) => '${minutes ~/ 60} ч ${minutes % 60} мин';
const _loaderMonths = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

class _LoaderDashboard extends StatefulWidget {
  final AppSession session;
  const _LoaderDashboard({required this.session});
  @override
  State<_LoaderDashboard> createState() => _LoaderDashboardState();
}

class _LoaderDashboardState extends State<_LoaderDashboard> {
  late final AccountToken _owner = AccountScope.capture();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _date = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  final _hours = TextEditingController(),
      _minutes = TextEditingController(text: '0');
  List<LoaderShift> _shifts = [];
  EmployeeAccount? _settings;
  String? _error, _editing;
  bool _loading = true, _busy = false;
  int _tab = 0;
  int _request = 0;
  List<LoaderShift> get _visible => _shifts
      .where((s) => s.day.startsWith(LoaderService.monthKey(_month)))
      .toList();
  int get _enteredMinutes =>
      (int.tryParse(_hours.text) ?? 0) * 60 +
      (int.tryParse(_minutes.text) ?? 0);
  int get _rate =>
      _shifts.where((s) => s.day == _editing).firstOrNull?.rateMinor ??
      _settings?.hourlyRateMinor ??
      0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _recentScroll.dispose();
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final settings = await _owner.bind(SessionService.ownLoaderSettings);
      final shifts = await _owner.bind(LoaderService.read);
      if (!mounted || !_owner.valid || request != _request) return;
      setState(() {
        _settings = settings;
        _shifts = shifts;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted && request == _request)
        setState(() {
          _loading = false;
          _error = _message(e);
        });
    }
  }

  String _message(Object e) => e is ArgumentError
      ? '${e.message}'
      : e is StateError
      ? '${e.message}'
      : 'Не удалось загрузить или сохранить данные. Повторите попытку.';
  Future<void> _save() async {
    if (_busy) return;
    final h = int.tryParse(_hours.text), m = int.tryParse(_minutes.text);
    if (h == null ||
        h < 0 ||
        m == null ||
        m < 0 ||
        m > 59 ||
        _enteredMinutes < 1 ||
        _enteredMinutes > 1440) {
      setState(
        () => _error = 'Введите часы от 0 до 24 и минуты от 0 до 59. Максимум за день — 24 часа.',
      );
      _showError();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _owner.bind(
        () => LoaderService.save(
          date: _date,
          minutes: _enteredMinutes,
          originalDay: _editing,
        ),
      );
      if (!mounted || !_owner.valid) return;
      setState(() {
        _month = DateTime(_date.year, _date.month);
        _editing = null;
        _hours.clear();
        _minutes.text = '0';
      });
      await _load();
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Смена сохранена')));
    } catch (e) {
      if (mounted) {
        setState(() => _error = _message(e));
        _showError();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _edit(LoaderShift shift) {
    setState(() {
      _editing = shift.day;
      _date = DateTime.parse(shift.day);
      _hours.text = '${shift.minutes ~/ 60}';
      _minutes.text = '${shift.minutes % 60}';
      _tab = 0;
      _error = null;
    });
  }

  Future<void> _delete(LoaderShift shift) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Удалить смену?'),
        content: Text(
          '${_loaderDate(DateTime.parse(shift.day))} · ${_loaderHours(shift.minutes)}\nНачисление за неё будет убрано.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted || !_owner.valid) return;
    setState(() => _busy = true);
    try {
      await _owner.bind(() => LoaderService.delete(shift.day));
      if (!mounted) return;
      if (_editing == shift.day)
        setState(() {
          _editing = null;
          _hours.clear();
          _minutes.text = '0';
        });
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _error = _message(e));
        _showError();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickMonth() async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (c) {
        var year = _month.year;
        return StatefulBuilder(
          builder: (c, change) => AlertDialog(
            title: Row(
              children: [
                IconButton(
                  onPressed: () => change(() => year--),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(child: Text('$year', textAlign: TextAlign.center)),
                IconButton(
                  onPressed: () => change(() => year++),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            content: SizedBox(
              width: 300,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < 12; i++)
                    TextButton(
                      onPressed: () => Navigator.pop(c, DateTime(year, i + 1)),
                      child: Text(_loaderMonths[i]),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (selected != null && mounted) setState(() => _month = selected);
  }

  void _showError() {
    if (_error != null && mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_error!)));
  }

  int get _accrued => _visible.fold<int>(0, (a, s) => a + s.amountMinor);
  int get _deduction =>
      _settings?.deductions[LoaderService.monthKey(_month)] ?? 0;
  int get _payable => math.max(0, _accrued - _deduction);
  String get _monthLabel => '${_loaderMonths[_month.month - 1]} ${_month.year}';
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (mounted && d != null) setState(() => _date = d);
  }

  Future<void> _enterHours() async {
    final hours = TextEditingController(text: _hours.text);
    final minutes = TextEditingController(text: _minutes.text);
    final result = await showDialog<List<String>>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF0B1820),
        title: const Text('Отработанное время'),
        content: SingleChildScrollView(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: hours,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: const InputDecoration(labelText: 'Часы'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: minutes,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: const InputDecoration(labelText: 'Минуты'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final h = int.tryParse(hours.text),
                  m = int.tryParse(minutes.text);
              if (h == null ||
                  m == null ||
                  h < 0 ||
                  m < 0 ||
                  m > 59 ||
                  h * 60 + m < 1 ||
                  h * 60 + m > 1440) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('От 1 минуты до 24 часов. Минуты: 0–59.'),
                  ),
                );
                return;
              }
              Navigator.pop(c, [hours.text, minutes.text]);
            },
            child: const Text('Готово'),
          ),
        ],
      ),
    );
    // Dialog route may still animate out; dispose controllers after it finishes.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      hours.dispose();
      minutes.dispose();
    });
    if (mounted && result != null)
      setState(() {
        _hours.text = result[0];
        _minutes.text = result[1];
      });
  }

  Widget _text(
    String text,
    double size, {
    Color color = Colors.white,
    FontWeight weight = FontWeight.w400,
    TextAlign align = TextAlign.left,
  }) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    textAlign: align,
    style: TextStyle(fontSize: size, color: color, fontWeight: weight),
  );
  Widget _fit(
    String text,
    double size, {
    Color color = Colors.white,
    FontWeight weight = FontWeight.w600,
    Alignment alignment = Alignment.centerLeft,
  }) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: alignment,
    child: _text(text, size, color: color, weight: weight),
  );
  Widget _tap(Widget child, VoidCallback? fn) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _busy ? null : fn,
      borderRadius: BorderRadius.circular(16),
      child: child,
    ),
  );

  static const _paperShift = 'assets/images/scenes/loader_notebook_shift.png';
  static const _paperHistory =
      'assets/images/scenes/loader_notebook_history.png';
  static const _ink = Color(0xFF17140F);
  final _recentScroll = ScrollController();
  void _setTime(int total) {
    if (_busy) return;
    total = total.clamp(0, 1440);
    HapticFeedback.selectionClick();
    setState(() {
      _hours.text = '${total ~/ 60}';
      _minutes.text = '${total % 60}';
    });
  }

  void _stepTime(int delta) => _setTime(_enteredMinutes + delta);

  Widget _paperScreen(double width, double height) {
    final insets = MediaQuery.paddingOf(context);
    final sx = width / 864, sy = (height - insets.top - insets.bottom) / 1536;
    // Extend only the top photograph behind the system status bar.
    // The paper sheets and their controls retain the same safe-area coordinates.
    Widget backgroundBand(
      String asset,
      double from,
      double to,
      double top,
      double bandHeight,
    ) => Positioned(
      left: 0,
      right: 0,
      top: top,
      height: bandHeight,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (_, box) {
            final imageHeight = box.maxHeight / (to - from);
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  top: -from * imageHeight,
                  width: width,
                  height: imageHeight,
                  child: RepaintBoundary(
                    child: Image.asset(asset, fit: BoxFit.fill),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    final headerEnd = insets.top + 110 * sy;
    final history = _tab == 1;
    Widget at(double x, double y, double w, double h, Widget child) =>
        Positioned(
          left: x * sx,
          top: insets.top + y * sy,
          width: w * sx,
          height: h * sy,
          child: child,
        );
    Widget label(
      String value,
      double size, {
      bool bold = false,
      Color color = _ink,
      bool center = false,
    }) => _fit(
      value,
      size * sx,
      color: color,
      weight: bold ? FontWeight.w800 : FontWeight.w400,
      alignment: center ? Alignment.center : Alignment.centerLeft,
    );
    Widget icon(IconData data, double size, {Color color = _ink}) =>
        Icon(data, size: size * sx, color: color);
    Widget heading(String value) => Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: _ink,
        fontSize: 39 * sx,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
      ),
    );
    Widget line() => const ColoredBox(color: Color(0x554D3C28));
    final worked = _visible.fold<int>(0, (sum, s) => sum + s.minutes);
    final digits =
        '${(_enteredMinutes ~/ 60).toString().padLeft(2, '0')}${(_enteredMinutes % 60).toString().padLeft(2, '0')}';
    // Row values and their hit areas share one layout, so scrolling stays aligned.
    Widget journal() => _visible.isEmpty
        ? Center(child: label('За этот месяц смен пока нет', 23))
        : Scrollbar(
            controller: _recentScroll,
            child: ListView.builder(
              key: ValueKey('journal-$_tab-${LoaderService.monthKey(_month)}'),
              controller: _recentScroll,
              padding: EdgeInsets.zero,
              itemCount: _visible.length,
              itemBuilder: (_, i) {
                final s = _visible[i], d = DateTime.parse(s.day);
                return SizedBox(
                  height: (history ? 61 : 65) * sy,
                  child: _tap(
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0x554D3C28)),
                        ),
                      ),
                      child: Row(
                        children: [
                          icon(Icons.calendar_month_outlined, 31),
                          SizedBox(width: 18 * sx),
                          Expanded(
                            flex: 3,
                            child: label(
                              '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}',
                              25,
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: label(_loaderHours(s.minutes), 24),
                          ),
                          Expanded(
                            flex: 4,
                            child: label(
                              _loaderMoney(s.amountMinor),
                              29,
                              bold: true,
                            ),
                          ),
                          icon(Icons.chevron_right, 28),
                        ],
                      ),
                    ),
                    () => _shiftActions(s),
                  ),
                );
              },
            ),
          );
    return Stack(
      children: [
        // Contiguous slices: no second full-size scene under SafeArea.
        backgroundBand(_paperShift, 0, 110 / 1536, 0, headerEnd),
        backgroundBand(
          history ? _paperHistory : _paperShift,
          110 / 1536,
          1,
          headerEnd,
          height - headerEnd,
        ),
        at(
          104,
          22,
          320,
          77,
          _tap(
            Row(
              children: [
                Container(
                  width: 73 * sx,
                  height: 73 * sx,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF12100C),
                    border: Border.all(color: _loaderGold, width: 2),
                  ),
                  child: Center(
                    child: label(
                      widget.session.displayName.characters.first.toUpperCase(),
                      40,
                      color: Colors.white,
                      center: true,
                    ),
                  ),
                ),
                SizedBox(width: 20 * sx),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      label(
                        widget.session.displayName,
                        31,
                        bold: true,
                        color: Colors.white,
                      ),
                      label('Грузчик ⌄', 23, color: const Color(0xFFCAC6BD)),
                    ],
                  ),
                ),
              ],
            ),
            () => _openAccountMenu(context, widget.session),
          ),
        ),
        at(
          492,
          32,
          270,
          60,
          _tap(
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12 * sx),
              decoration: BoxDecoration(
                color: const Color(0xDA16130F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _loaderGold),
              ),
              child: Row(
                children: [
                  icon(Icons.calendar_month_outlined, 27, color: Colors.white),
                  SizedBox(width: 12 * sx),
                  Expanded(
                    child: label(
                      '$_monthLabel ⌄',
                      25,
                      bold: true,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            _pickMonth,
          ),
        ),
        at(
          130,
          126,
          393,
          75,
          label(history ? 'История' : 'Моя работа', 63, bold: true),
        ),
        at(
          137,
          202,
          381,
          36,
          label(
            history ? 'Все смены за месяц' : 'Склад · Погрузка · Разгрузка',
            25,
          ),
        ),
        if (!history) ...[
          at(181, 272, 494, 38, label('Заработано за месяц', 30, bold: true)),
          at(184, 312, 500, 83, label(_loaderMoney(_accrued), 71, bold: true)),
          at(181, 423, 49, 55, icon(Icons.schedule, 49)),
          at(254, 411, 166, 43, label(_loaderHours(worked), 34, bold: true)),
          at(254, 458, 171, 29, label('Отработано', 23)),
          at(477, 423, 49, 55, icon(Icons.calendar_month_outlined, 49)),
          at(545, 411, 137, 43, label('${_visible.length}', 36, bold: true)),
          at(545, 458, 145, 29, label('Смены', 23)),
          at(184, 517, 245, 29, label('Ставка', 23)),
          at(
            184,
            551,
            245,
            37,
            label(
              '${_loaderMoney(_settings?.hourlyRateMinor ?? 0)} / час',
              28,
              bold: true,
            ),
          ),
          at(526, 517, 174, 29, label('К получению', 23)),
          at(526, 551, 174, 37, label(_loaderMoney(_payable), 32, bold: true)),
          at(
            158,
            638,
            345,
            50,
            heading(_editing == null ? 'Добавить смену' : 'Изменить смену'),
          ),
          at(
            554,
            646,
            207,
            40,
            _tap(
              Row(
                children: [
                  icon(Icons.calendar_month_outlined, 28),
                  SizedBox(width: 10 * sx),
                  Expanded(child: label(_loaderDate(_date), 25, bold: true)),
                ],
              ),
              _pickDate,
            ),
          ),
          at(159, 707, 450, 32, label('Отработано часов', 23)),
          if (_editing != null)
            at(
              696,
              701,
              72,
              39,
              _tap(
                icon(Icons.close, 28),
                () => setState(() {
                  _editing = null;
                  _hours.clear();
                  _minutes.text = '0';
                }),
              ),
            ),
          at(
            168,
            773,
            74,
            79,
            _tap(
              icon(Icons.remove, 42, color: const Color(0xFFDBD4C7)),
              () => _stepTime(-60),
            ),
          ),
          at(692, 757, 70, 79, _tap(icon(Icons.add, 48), () => _stepTime(60))),
          // Four live digits sit on the photographed mechanical drums.
          for (var i = 0; i < 4; i++)
            at(
              [289.0, 365.0, 486.0, 560.0][i],
              765,
              59,
              93,
              _tap(
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 120),
                    child: Text(
                      digits[i],
                      key: ValueKey('$i-${digits[i]}'),
                      style: TextStyle(
                        color: const Color(0xFFE6E1D7),
                        fontSize: 60 * sx,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                _enterHours,
              ),
            ),
          at(
            425,
            791,
            34,
            36,
            _tap(
              label('ч', 25, bold: true, color: Colors.white, center: true),
              _enterHours,
            ),
          ),
          at(
            562,
            849,
            62,
            23,
            _tap(
              label('мин', 18, color: Colors.white, center: true),
              _enterHours,
            ),
          ),
          for (var i = 0; i < 4; i++)
            at(
              [166.0, 322.0, 476.0, 636.0][i],
              899,
              128,
              49,
              _tap(
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: _enteredMinutes == [480, 600, 720, -1][i]
                        ? Border.all(color: const Color(0xFFAD6416), width: 2)
                        : null,
                  ),
                  child: label(
                    ['8 ч', '10 ч', '12 ч', '+1 ч'][i],
                    28,
                    bold: true,
                    center: true,
                  ),
                ),
                () => i == 3 ? _stepTime(60) : _setTime([480, 600, 720][i]),
              ),
            ),
          at(
            189,
            974,
            553,
            68,
            _tap(
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon(Icons.check_circle, 42),
                  SizedBox(width: 18 * sx),
                  Flexible(
                    child: label(
                      _busy ? 'Сохранение…' : 'Сохранить смену',
                      36,
                      bold: true,
                    ),
                  ),
                ],
              ),
              _loading || _settings == null ? null : _save,
            ),
          ),
          at(137, 1110, 475, 50, heading('Последние смены')),
          at(
            699,
            1106,
            64,
            43,
            _tap(label('Все ›', 23), () => setState(() => _tab = 1)),
          ),
          at(153, 1171, 608, 174, journal()),
        ] else ...[
          at(155, 292, 532, 41, label('Итоги за месяц', 30, bold: true)),
          at(145, 341, 600, 1, line()),
          at(146, 355, 51, 57, icon(Icons.schedule, 49)),
          at(214, 352, 138, 40, label(_loaderHours(worked), 33, bold: true)),
          at(214, 398, 143, 27, label('Отработано', 20)),
          at(371, 355, 49, 57, icon(Icons.calendar_month_outlined, 46)),
          at(433, 352, 80, 40, label('${_visible.length}', 34, bold: true)),
          at(433, 398, 87, 27, label('Смены', 20)),
          at(539, 352, 203, 43, label(_loaderMoney(_accrued), 34, bold: true)),
          at(539, 398, 203, 27, label('Заработано', 21)),
          at(145, 484, 599, 52, heading('Все смены за месяц')),
          at(147, 538, 585, 2, line()),
          at(146, 550, 585, 772, journal()),
        ],
        for (var i = 0; i < 2; i++)
          at(
            108 + i * 350,
            1399,
            290,
            91,
            _tap(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon(
                    i == 0
                        ? Icons.work_history_outlined
                        : Icons.receipt_long_outlined,
                    34,
                    color: _tab == i
                        ? const Color(0xFFF0AD45)
                        : const Color(0xFFCAC6BD),
                  ),
                  SizedBox(height: 5 * sy),
                  label(
                    i == 0 ? 'Смена' : 'История',
                    26,
                    bold: _tab == i,
                    color: _tab == i
                        ? const Color(0xFFF0AD45)
                        : const Color(0xFFCAC6BD),
                    center: true,
                  ),
                ],
              ),
              () => setState(() => _tab = i),
            ),
          ),
        if (_loading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x55000000),
              child: Center(
                child: CircularProgressIndicator(color: _loaderGold),
              ),
            ),
          ),
        if (_settings == null && !_loading)
          at(
            142,
            274,
            576,
            63,
            _tap(
              Container(
                color: const Color(0xFFF0D6B3),
                child: label(
                  'Ошибка загрузки · Повторить',
                  26,
                  bold: true,
                  center: true,
                ),
              ),
              _load,
            ),
          ),
      ],
    );
  }

  Future<void> _shiftActions(LoaderShift s) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0D1921),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(_loaderDate(DateTime.parse(s.day))),
              subtitle: Text(
                '${_loaderHours(s.minutes)} · ${_loaderMoney(s.amountMinor)}\nСтавка: ${_loaderMoney(s.rateMinor)} / ч',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: _loaderGold),
              title: const Text('Изменить'),
              onTap: () => Navigator.pop(c, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: _loaderGold),
              title: const Text('Удалить'),
              onTap: () => Navigator.pop(c, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || !_owner.valid) return;
    if (action == 'edit') _edit(s);
    if (action == 'delete') await _delete(s);
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme
          .copyWith(primary: _loaderGold, secondary: _loaderGold),
    ),
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF07121A),
        body: LayoutBuilder(
          builder: (_, box) => _paperScreen(box.maxWidth, box.maxHeight),
        ),
      ),
    ),
  );
}
