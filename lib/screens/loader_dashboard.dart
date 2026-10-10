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
  Widget _tap(Widget child, VoidCallback? fn) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _busy ? null : fn,
      borderRadius: BorderRadius.circular(16),
      child: child,
    ),
  );

  static const _art = 'assets/images/scenes/loader_premium.png';
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
  // Crop the same cached texture at runtime. The bands let the header be shorter
  // and the recent-shifts frame taller without stretching the entire screen.
  Widget _artSlice(double top, double bottom) => RepaintBoundary(
    child: LayoutBuilder(
      builder: (_, box) {
        final fullHeight = box.maxHeight / (bottom - top);
        return ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: -top * fullHeight,
                width: box.maxWidth,
                height: fullHeight,
                child: Image.asset(
                  _art,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  Widget _recess(
    Widget child, {
    bool active = false,
    bool bronze = false,
    double radius = 7,
  }) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: bronze
            ? const [Color(0xFF936E39), Color(0xFF4D321A), Color(0xFF8E6835)]
            : active
            ? const [Color(0xFF3E2A13), Color(0xFF11171A), Color(0xFF493219)]
            : const [Color(0xF8102533), Color(0xF5040E16), Color(0xF40A1B28)],
      ),
      border: Border.all(
        color: active || bronze
            ? const Color(0xFFD1AC67)
            : const Color(0xFF81735B),
        width: 0.8,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x99000000),
          offset: Offset(0, 2),
          blurRadius: 2,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius - 1),
          border: Border.all(color: const Color(0x55365B73), width: 0.7),
        ),
        child: child,
      ),
    ),
  );
  Widget _profile(double scale) => _tap(
    Row(
      children: [
        Container(
          width: 54 * scale,
          height: 54 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF39434A), Color(0xFF07121B)],
            ),
            border: Border.all(color: _loaderGold, width: 1.4),
          ),
          child: Center(
            child: _text(
              widget.session.displayName.characters.first.toUpperCase(),
              29 * scale,
              color: const Color(0xFFE8D5AD),
              weight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: 13 * scale),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _text(
                widget.session.displayName,
                23 * scale,
                weight: FontWeight.w700,
              ),
              _text('Грузчик ⌄', 18 * scale, color: _loaderMuted),
            ],
          ),
        ),
      ],
    ),
    () => _openAccountMenu(context, widget.session),
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
    final worked = _visible.fold<int>(0, (a, s) => a + s.minutes);
    final remaining = math.max(0, _deduction - _accrued);
    final progress = _deduction <= 0
        ? 0.0
        : (_accrued / _deduction).clamp(0.0, 1.0);
    Widget ledger(String label, String value, {bool info = false}) => _tap(
      _recess(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 13 * sx),
          child: Row(
            children: [
              Expanded(
                child: _text(label, 21 * sx, color: const Color(0xFFCFD7DC)),
              ),
              if (info)
                Padding(
                  padding: EdgeInsets.only(right: 12 * sx),
                  child: icon(Icons.info_outline, 20, color: _loaderMuted),
                ),
              Flexible(
                child: _fit(value, 23 * sx, alignment: Alignment.centerRight),
              ),
            ],
          ),
        ),
      ),
      _payInfo,
    );
    return Stack(
      children: [
        at(0, 0, 709, 300, _artSlice(0, .247)),
        at(0, 300, 709, 360, _artSlice(.247, .49)),
        at(0, 660, 709, 410, _artSlice(.49, .75)),
        at(0, 1070, 709, 355, _artSlice(.75, .92)),
        at(0, 1425, 709, 111, _artSlice(.92, 1)),
        at(40, 12, 280, 69, _profile(sx)),
        at(
          494,
          19,
          181,
          47,
          _tap(
            _recess(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10 * sx),
                child: _fit('$_monthLabel ⌄', 19 * sx),
              ),
            ),
            _pickMonth,
          ),
        ),
        at(
          42,
          211,
          552,
          68,
          _fit('Моя работа', 57 * sx, weight: FontWeight.w700),
        ),
        // Summary: three recessed instruments and two information rows.
        at(
          63,
          333,
          268,
          95,
          _recess(
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * sx,
                vertical: 8 * sy,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _fit(
                      _loaderMoney(_accrued),
                      45 * sx,
                      color: const Color(0xFFE2BC76),
                      weight: FontWeight.w700,
                    ),
                  ),
                  _text(
                    'Начислено за месяц',
                    17 * sx,
                    color: const Color(0xFFD2DCE1),
                  ),
                ],
              ),
            ),
          ),
        ),
        at(
          341,
          333,
          111,
          95,
          _recess(
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _fit(
                  worked % 60 == 0
                      ? '${worked ~/ 60} ч'
                      : '${(worked / 60).toStringAsFixed(1).replaceAll('.', ',')} ч',
                  29 * sx,
                ),
                SizedBox(height: 4 * sy),
                _text('Отработано', 16 * sx, color: _loaderMuted),
              ],
            ),
          ),
        ),
        at(
          461,
          333,
          95,
          95,
          _recess(
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _text('${_visible.length}', 29 * sx, weight: FontWeight.w600),
                SizedBox(height: 4 * sy),
                _text('Смены', 16 * sx, color: _loaderMuted),
              ],
            ),
          ),
        ),
        at(
          63,
          445,
          493,
          43,
          ledger('Удержание', _loaderMoney(_deduction), info: true),
        ),
        at(63, 495, 493, 43, ledger('К получению', _loaderMoney(_payable))),
        at(
          64,
          557,
          435,
          30,
          _recess(
            Padding(
              padding: EdgeInsets.all(4 * sx),
              child: Row(
                children: [
                  for (var i = 0; i < 10; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 1 * sx),
                        child: LayoutBuilder(
                          builder: (_, box) => Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B2A35),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: (progress * 10 - i).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  heightFactor: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFFECC073),
                                          Color(0xFF9D6325),
                                        ],
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
                ],
              ),
            ),
          ),
        ),
        at(
          508,
          554,
          51,
          34,
          _fit(
            _deduction == 0 ? '—' : '${(progress * 100).floor()}%',
            20 * sx,
            color: _loaderGold,
          ),
        ),
        at(
          67,
          596,
          488,
          25,
          _fit(
            _deduction == 0
                ? 'Удержаний за этот месяц нет'
                : remaining > 0
                ? 'До покрытия удержания — ${_loaderMoney(remaining)}'
                : 'Удержание покрыто начислениями',
            17 * sx,
            color: const Color(0xFFCBD3D9),
          ),
        ),
        at(
          200,
          623,
          356,
          23,
          _fit(
            'Ставка ${_loaderMoney(_settings?.hourlyRateMinor ?? 0)} / час',
            16 * sx,
            color: _loaderMuted,
            alignment: Alignment.centerRight,
          ),
        ),
        // Shift form with live hour presets and an exact hours/minutes editor.
        at(
          65,
          686,
          340,
          45,
          _fit(
            _editing == null ? 'Добавить смену' : 'Изменить смену',
            33 * sx,
            weight: FontWeight.w700,
          ),
        ),
        at(
          425,
          687,
          222,
          45,
          _tap(
            _recess(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12 * sx),
                child: Row(
                  children: [
                    Expanded(child: _fit(_loaderDate(_date), 23 * sx)),
                    icon(Icons.calendar_month_outlined, 25),
                  ],
                ),
              ),
            ),
            _pickDate,
          ),
        ),
        at(
          74,
          747,
          481,
          30,
          _text('Отработано часов', 21 * sx, color: const Color(0xFFB6C3CC)),
        ),
        if (_editing != null)
          at(
            591,
            741,
            57,
            35,
            _tap(
              Center(child: icon(Icons.close, 25)),
              () => setState(() {
                _editing = null;
                _hours.clear();
                _minutes.text = '0';
              }),
            ),
          ),
        at(
          73,
          782,
          67,
          59,
          _tap(
            _recess(Center(child: icon(Icons.remove, 34))),
            () => _stepTime(-60),
          ),
        ),
        at(
          151,
          782,
          401,
          59,
          _tap(
            _recess(
              Center(
                child: _fit(
                  _hours.text.isEmpty
                      ? 'Выберите часы'
                      : '${_enteredMinutes ~/ 60} ч ${(_enteredMinutes % 60).toString().padLeft(2, '0')} мин',
                  32 * sx,
                  color: const Color(0xFFF1DCB3),
                ),
              ),
            ),
            _enterHours,
          ),
        ),
        at(
          563,
          782,
          73,
          59,
          _tap(
            _recess(Center(child: icon(Icons.add, 34))),
            () => _stepTime(60),
          ),
        ),
        for (var i = 0; i < 3; i++)
          at(
            73 + i * 192,
            854,
            179,
            52,
            _tap(
              _recess(
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_enteredMinutes == [480, 600, 720][i]) ...[
                      Container(
                        width: 8 * sx,
                        height: 8 * sx,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8BB68),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 12 * sx),
                    ],
                    _text(
                      '${[8, 10, 12][i]} ч',
                      25 * sx,
                      color: const Color(0xFFECE5D5),
                    ),
                  ],
                ),
                active: _enteredMinutes == [480, 600, 720][i],
              ),
              () => _setTime([480, 600, 720][i]),
            ),
          ),
        at(
          73,
          919,
          563,
          46,
          _recess(
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 13 * sx),
              child: Row(
                children: [
                  Expanded(child: _text('За смену', 21 * sx)),
                  Flexible(
                    child: _fit(
                      _loaderMoney((_enteredMinutes * _rate / 60).round()),
                      25 * sx,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        at(
          73,
          981,
          563,
          59,
          _tap(
            _recess(
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon(Icons.save_outlined, 29, color: const Color(0xFFF5E4C4)),
                  SizedBox(width: 12 * sx),
                  _text(
                    _busy ? 'Сохранение…' : 'Сохранить смену',
                    26 * sx,
                    weight: FontWeight.w600,
                    color: const Color(0xFFF5E4C4),
                  ),
                ],
              ),
              bronze: true,
            ),
            _loading || _settings == null ? null : _save,
          ),
        ),
        // Increased list height, all monthly records available through inner scroll.
        at(
          65,
          1093,
          463,
          45,
          _fit('Последние смены', 30 * sx, weight: FontWeight.w700),
        ),
        at(
          573,
          1091,
          72,
          47,
          _tap(
            Center(child: _text('Все ›', 22 * sx, color: _loaderMuted)),
            () => setState(() => _tab = 1),
          ),
        ),
        at(
          64,
          1150,
          584,
          240,
          _visible.isEmpty
              ? Center(
                  child: _text(
                    'За этот месяц смен пока нет',
                    21 * sx,
                    color: _loaderMuted,
                  ),
                )
              : Scrollbar(
                  controller: _recentScroll,
                  child: ListView.builder(
                    controller: _recentScroll,
                    padding: EdgeInsets.zero,
                    itemCount: _visible.length,
                    itemBuilder: (_, i) {
                      final s = _visible[i], d = DateTime.parse(s.day);
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8 * sy),
                        child: SizedBox(
                          height: 52 * sy,
                          child: _tap(
                            _recess(
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 13 * sx,
                                ),
                                child: Row(
                                  children: [
                                    icon(
                                      Icons.calendar_month_outlined,
                                      23,
                                      color: _loaderMuted,
                                    ),
                                    SizedBox(width: 13 * sx),
                                    Expanded(
                                      flex: 5,
                                      child: _fit(
                                        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} · ${_loaderHours(s.minutes)}',
                                        21 * sx,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: _fit(
                                        _loaderMoney(s.amountMinor),
                                        22 * sx,
                                        alignment: Alignment.centerRight,
                                      ),
                                    ),
                                    SizedBox(width: 10 * sx),
                                    icon(
                                      Icons.chevron_right,
                                      24,
                                      color: _loaderMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            () => _shiftActions(s),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
        at(104, 1451, 232, 58, _navButton(0, sx)),
        at(370, 1451, 232, 58, _navButton(1, sx)),
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
            65,
            155,
            580,
            49,
            _tap(
              _recess(
                Center(
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
    _recess(
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            index == 0 ? Icons.schedule : Icons.receipt_long_outlined,
            color: _tab == index ? _loaderGold : _loaderMuted,
            size: 25 * scale,
          ),
          SizedBox(width: 12 * scale),
          _text(
            index == 0 ? 'Смена' : 'История',
            23 * scale,
            color: _tab == index ? const Color(0xFFE6CA97) : _loaderMuted,
          ),
        ],
      ),
      active: _tab == index,
    ),
    () => setState(() => _tab = index),
  );

  Widget _historyScreen(double width) {
    const days = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _artSlice(0, .247),
              Positioned(
                left: 16,
                top: 8,
                width: width * .5,
                height: 44,
                child: _profile(.65),
              ),
              Positioned(
                left: 24,
                bottom: 10,
                right: 16,
                child: _fit('История смен', 29, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
          child: _recess(
            Row(
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
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Row(
            children: [
              Expanded(
                child: _fit(
                  '${_visible.length} смен · ${_loaderHours(_visible.fold<int>(0, (a, s) => a + s.minutes))}',
                  14,
                  color: _loaderMuted,
                ),
              ),
              const SizedBox(width: 8),
              _text(
                _loaderMoney(_accrued),
                17,
                color: _loaderGold,
                weight: FontWeight.w600,
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _artSlice(.75, .92),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                child: Column(
                  children: [
                    Row(
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
                    const SizedBox(height: 12),
                    Expanded(
                      child: _visible.isEmpty
                          ? Center(
                              child: _text(
                                'Смен пока нет',
                                16,
                                color: _loaderMuted,
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: _visible.length,
                              itemBuilder: (_, i) {
                                final s = _visible[i],
                                    d = DateTime.parse(s.day);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: _tap(
                                    _recess(
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 15,
                                        ),
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
                                                    19,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  _text(
                                                    days[d.weekday - 1],
                                                    12,
                                                    color: _loaderMuted,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: _fit(
                                                _loaderHours(s.minutes),
                                                16,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 4,
                                              child: _fit(
                                                _loaderMoney(s.amountMinor),
                                                17,
                                                color: const Color(0xFFE1C28E),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.more_vert,
                                              color: _loaderMuted,
                                              size: 17,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    () => _shiftActions(s),
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
        ),
        SizedBox(
          height: 78,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _artSlice(.92, 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 42,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(child: _navButton(0, .65)),
                    const SizedBox(width: 18),
                    Expanded(child: _navButton(1, .65)),
                  ],
                ),
              ),
            ],
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
            const RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_art),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (_, box) => _tab == 1
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
