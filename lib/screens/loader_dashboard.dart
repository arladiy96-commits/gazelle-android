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

  Future<void> _payInfo() => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF0B1820),
      title: Text(_monthLabel),
      content: Text(
        'Начислено: ${_loaderMoney(_accrued)}\nУдержание: ${_loaderMoney(_deduction)}\nК получению: ${_loaderMoney(_payable)}\n\nСтавку и удержание назначает администратор. Ставка сохранённых смен не меняется.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Понятно'),
        ),
      ],
    ),
  );
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
  BoxDecoration _metal({bool active = false, double radius = 18}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: active ? _loaderGold : const Color(0xFF425562),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? const [Color(0xF042301B), Color(0xF010181C)]
              : const [Color(0xED162630), Color(0xEE08131B)],
        ),
      );
  Widget _tap(Widget child, VoidCallback? fn) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _busy ? null : fn,
      borderRadius: BorderRadius.circular(16),
      child: child,
    ),
  );

  Widget _referenceScreen(double width, double height) {
    final sx = width / 709, sy = height / 1536;
    Widget at(double x, double y, double w, double h, Widget child) =>
        Positioned(
          left: x * sx,
          top: y * sy,
          width: w * sx,
          height: h * sy,
          child: child,
        );
    Widget icon(IconData data, double size, {Color color = _loaderGold}) =>
        Icon(data, size: size * sx, color: color);
    Widget line() => const ColoredBox(color: Color(0xFF344854));
    final worked = _visible.fold<int>(0, (a, s) => a + s.minutes);
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: Image.asset(
              'assets/images/scenes/loader_reference.png',
              fit: BoxFit.fill,
            ),
          ),
        ),
        at(
          24,
          25,
          72,
          72,
          _tap(
            Container(
              decoration: _metal(radius: 60),
              child: icon(Icons.arrow_back, 32),
            ),
            () => _openAccountMenu(context, widget.session),
          ),
        ),
        at(230, 19, 85, 80, icon(Icons.engineering_outlined, 70)),
        at(329, 24, 180, 64, _fit('Грузчик', 42 * sx)),
        at(
          518,
          30,
          172,
          60,
          _tap(
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10 * sx),
              decoration: _metal(radius: 28),
              child: _fit('$_monthLabel ⌄', 19 * sx),
            ),
            _pickMonth,
          ),
        ),
        at(
          49,
          167,
          300,
          36,
          _text('Личный кабинет', 21 * sx, color: _loaderMuted),
        ),
        at(
          43,
          204,
          310,
          68,
          _fit('Моя работа', 50 * sx, weight: FontWeight.w700),
        ),
        at(
          49,
          278,
          275,
          35,
          _tap(
            _text(
              '${widget.session.displayName} · Грузчик ⌄',
              19 * sx,
              color: const Color(0xFFBCC7CE),
            ),
            () => _openAccountMenu(context, widget.session),
          ),
        ),
        // Monthly panel matches the reference: earnings left, hours and shifts right.
        at(58, 444, 52, 56, icon(Icons.account_balance_wallet_outlined, 48)),
        at(119, 442, 267, 38, _text('Начислено за месяц', 23 * sx)),
        at(
          119,
          481,
          266,
          57,
          _fit(
            _loaderMoney(_accrued),
            47 * sx,
            color: _loaderGold,
            weight: FontWeight.w700,
          ),
        ),
        at(387, 461, 1, 67, line()),
        at(410, 466, 33, 33, icon(Icons.schedule, 30)),
        at(
          451,
          462,
          95,
          44,
          _fit(
            worked % 60 == 0
                ? '${worked ~/ 60} ч'
                : '${(worked / 60).toStringAsFixed(1).replaceAll('.', ',')} ч',
            29 * sx,
          ),
        ),
        at(
          416,
          504,
          128,
          29,
          _text('Отработано', 15 * sx, color: _loaderMuted),
        ),
        at(552, 461, 1, 67, line()),
        at(572, 466, 30, 33, icon(Icons.event_note, 29)),
        at(614, 462, 48, 42, _fit('${_visible.length}', 29 * sx)),
        at(612, 504, 58, 29, _text('Смен', 15 * sx, color: _loaderMuted)),
        at(53, 546, 610, 1, line()),
        at(62, 562, 37, 43, icon(Icons.toll, 35)),
        at(
          111,
          565,
          241,
          41,
          _fit(
            'Ставка ${_loaderMoney(_settings?.hourlyRateMinor ?? 0)} / час',
            19 * sx,
          ),
        ),
        at(359, 559, 1, 45, line()),
        at(
          381,
          565,
          282,
          42,
          _tap(
            Row(
              children: [
                Expanded(
                  child: _text('К получению', 17 * sx, color: _loaderMuted),
                ),
                SizedBox(width: 6 * sx),
                Flexible(
                  child: _fit(
                    _loaderMoney(_payable),
                    32 * sx,
                    color: const Color(0xFFB4D8E1),
                  ),
                ),
              ],
            ),
            _payInfo,
          ),
        ),
        // One compact time field on the page; precise hours/minutes in its editor.
        at(56, 672, 40, 40, icon(Icons.add_circle_outline, 39)),
        at(
          113,
          672,
          470,
          44,
          _text(
            _editing == null ? 'Добавить смену' : 'Изменить смену',
            28 * sx,
            weight: FontWeight.w600,
          ),
        ),
        if (_editing != null)
          at(
            615,
            668,
            40,
            44,
            _tap(
              icon(Icons.close, 28),
              () => setState(() {
                _editing = null;
                _hours.clear();
                _minutes.text = '0';
              }),
            ),
          ),
        at(73, 732, 480, 28, _text('Дата', 19 * sx, color: _loaderMuted)),
        at(
          86,
          758,
          560,
          62,
          _tap(
            Container(
              padding: EdgeInsets.symmetric(horizontal: 22 * sx),
              decoration: _metal(radius: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _text(
                      _loaderDate(_date),
                      27 * sx,
                      weight: FontWeight.w500,
                    ),
                  ),
                  icon(Icons.calendar_month_outlined, 30, color: _loaderMuted),
                ],
              ),
            ),
            _pickDate,
          ),
        ),
        at(
          73,
          837,
          550,
          30,
          _text('Отработано часов', 19 * sx, color: _loaderMuted),
        ),
        at(
          83,
          869,
          558,
          58,
          _tap(
            Container(
              padding: EdgeInsets.symmetric(horizontal: 17 * sx),
              decoration: _metal(radius: 16),
              child: Row(
                children: [
                  icon(Icons.schedule, 29, color: _loaderMuted),
                  SizedBox(width: 18 * sx),
                  Expanded(
                    child: _text(
                      _hours.text.isEmpty
                          ? 'Введите количество часов'
                          : _loaderHours(_enteredMinutes),
                      21 * sx,
                      color: _hours.text.isEmpty
                          ? const Color(0xFF7F939F)
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            _enterHours,
          ),
        ),
        at(61, 938, 585, 1, line()),
        at(64, 947, 340, 37, _text('За эту смену', 23 * sx)),
        at(
          417,
          944,
          227,
          40,
          _fit(
            _loaderMoney((_enteredMinutes * _rate / 60).round()),
            31 * sx,
            color: const Color(0xFFB4D8E1),
            alignment: Alignment.centerRight,
          ),
        ),
        at(
          62,
          994,
          586,
          63,
          _tap(
            Container(
              decoration: _metal(active: true, radius: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon(Icons.save_outlined, 32),
                  SizedBox(width: 14 * sx),
                  _text(
                    _busy ? 'Сохранение…' : 'Сохранить смену',
                    24 * sx,
                    color: _loaderGold,
                    weight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            _loading || _settings == null ? null : _save,
          ),
        ),
        at(63, 1106, 35, 42, icon(Icons.history, 38)),
        at(
          115,
          1106,
          420,
          40,
          _text('Последние смены', 27 * sx, weight: FontWeight.w600),
        ),
        at(
          565,
          1105,
          89,
          45,
          _tap(
            Container(
              decoration: _metal(radius: 16),
              child: Center(
                child: _text('Все ›', 20 * sx, color: _loaderMuted),
              ),
            ),
            () => setState(() => _tab = 1),
          ),
        ),
        at(
          51,
          1164,
          607,
          151,
          _visible.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon(
                      Icons.engineering_outlined,
                      69,
                      color: const Color(0xFF49606D),
                    ),
                    SizedBox(height: 9 * sy),
                    _text(
                      'Смен за этот месяц пока нет',
                      20 * sx,
                      color: const Color(0xFF8295A1),
                    ),
                  ],
                )
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final s in _visible.take(3))
                      _tap(
                        Container(
                          height: 49 * sy,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFF344854)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _text(
                                  _loaderDate(DateTime.parse(s.day)),
                                  20 * sx,
                                ),
                              ),
                              Expanded(
                                child: _fit(_loaderHours(s.minutes), 19 * sx),
                              ),
                              Expanded(
                                child: _fit(
                                  _loaderMoney(s.amountMinor),
                                  21 * sx,
                                  color: _loaderGold,
                                  alignment: Alignment.centerRight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        () => _edit(s),
                      ),
                  ],
                ),
        ),
        at(31, 1411, 299, 88, _navButton(0, sx)),
        at(384, 1411, 297, 88, _navButton(1, sx)),
        if (_loading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x77061018),
              child: Center(
                child: CircularProgressIndicator(color: _loaderGold),
              ),
            ),
          ),
        if (_settings == null && !_loading)
          at(
            70,
            337,
            570,
            60,
            _tap(
              Container(
                decoration: _metal(),
                child: Center(
                  child: _text(
                    'Ошибка загрузки · Повторить',
                    22 * sx,
                    color: _loaderGold,
                  ),
                ),
              ),
              _load,
            ),
          ),
      ],
    );
  }

  Widget _navButton(int index, double scale) => _tap(
    Container(
      decoration: _metal(active: _tab == index, radius: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            index == 0 ? Icons.add_task : Icons.receipt_long_outlined,
            color: _tab == index ? _loaderGold : _loaderMuted,
            size: 28 * scale,
          ),
          SizedBox(height: 5 * scale),
          _text(
            index == 0 ? 'Смена' : 'История',
            21 * scale,
            color: _tab == index ? _loaderGold : _loaderMuted,
          ),
        ],
      ),
    ),
    () => setState(() => _tab = index),
  );

  Widget _historyScreen(double width) {
    const days = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    return Column(
      children: [
        SizedBox(
          height: 175,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    'assets/images/scenes/loader_reference.png',
                    width: width,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xA800080C), Color(0x0000080C)],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: 12,
                child: _tap(
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, color: _loaderGold),
                  ),
                  () => setState(() => _tab = 0),
                ),
              ),
              Positioned(
                left: 25,
                top: 65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _text('Личный кабинет', 13, color: _loaderMuted),
                    const SizedBox(height: 7),
                    _text('Моя работа', 29, weight: FontWeight.w700),
                    const SizedBox(height: 8),
                    _text('Грузчик', 14, color: _loaderGold),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: _metal(active: true),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
                icon: const Icon(Icons.chevron_left, color: _loaderGold),
              ),
              Expanded(
                child: TextButton(
                  onPressed: _pickMonth,
                  child: _text(
                    _monthLabel,
                    18,
                    weight: FontWeight.w600,
                    align: TextAlign.center,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
                icon: const Icon(Icons.chevron_right, color: _loaderGold),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: _loaderGold),
              const SizedBox(width: 12),
              _text('Детализация по дням', 21, weight: FontWeight.w600),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.fromLTRB(9, 14, 9, 0),
            decoration: _metal(active: true, radius: 22),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: _text('Дата', 12, color: _loaderMuted),
                      ),
                      Expanded(
                        flex: 3,
                        child: _text('Часы', 12, color: _loaderMuted),
                      ),
                      Expanded(
                        flex: 4,
                        child: _text('Заработок', 12, color: _loaderMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _visible.isEmpty
                      ? Center(
                          child: _text(
                            'За этот месяц смен пока нет',
                            14,
                            color: _loaderMuted,
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _visible.length,
                          itemBuilder: (c, i) {
                            final s = _visible[i], d = DateTime.parse(s.day);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: _metal(radius: 17),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(17),
                                onTap: _busy ? null : () => _shiftActions(s),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 15,
                                  ),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _text(
                                                '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}',
                                                20,
                                              ),
                                              const SizedBox(height: 5),
                                              _text(
                                                days[d.weekday - 1],
                                                12,
                                                color: _loaderMuted,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const VerticalDivider(
                                          width: 15,
                                          color: Color(0xFF293944),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: _fit(
                                            s.minutes % 60 == 0
                                                ? '${s.minutes ~/ 60} ч'
                                                : _loaderHours(s.minutes),
                                            17,
                                          ),
                                        ),
                                        const VerticalDivider(
                                          width: 15,
                                          color: Color(0xFF293944),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: _fit(
                                            _loaderMoney(s.amountMinor),
                                            18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                Expanded(child: _navButton(0, 0.65)),
                const SizedBox(width: 16),
                Expanded(child: _navButton(1, 0.65)),
              ],
            ),
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: Image.asset(
                  'assets/images/scenes/loader_reference.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (_tab == 1) const ColoredBox(color: Color(0xCE041019)),
            SafeArea(
              child: LayoutBuilder(
                builder: (c, box) => _tab == 1
                    ? _historyScreen(box.maxWidth)
                    : _referenceScreen(box.maxWidth, box.maxHeight),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
