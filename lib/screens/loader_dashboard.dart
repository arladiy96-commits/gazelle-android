part of 'app_shell.dart';

const _loaderGold = Color(0xFFC7A568);
const _loaderMuted = Color(0xFFAAB7BF);
String _loaderMoney(int minor) =>
    '${(minor / 100).toStringAsFixed(2).replaceAll('.', ',')} ₸';
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
      if (mounted) setState(() => _error = _message(e));
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
      if (mounted) setState(() => _error = _message(e));
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

  Widget _panel(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xF20B1820),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0x887C704E)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
  Widget _label(String s) =>
      Text(s, style: const TextStyle(color: _loaderMuted, fontSize: 12));
  Widget _row(String label, String value, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _loaderMuted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: strong ? _loaderGold : Colors.white,
              fontSize: strong ? 22 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _summary() {
    final rows = _visible,
        minutes = rows.fold<int>(0, (a, s) => a + s.minutes),
        accrued = rows.fold<int>(0, (a, s) => a + s.amountMinor);
    final deduction =
        _settings?.deductions[LoaderService.monthKey(_month)] ?? 0;
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('НАЧИСЛЕНО ЗА МЕСЯЦ'),
          const SizedBox(height: 5),
          Text(
            _loaderMoney(accrued),
            style: const TextStyle(
              fontSize: 30,
              color: _loaderGold,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 6,
            children: [
              Text(
                '◷ ${_loaderHours(minutes)}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'Смен: ${rows.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const Divider(height: 26, color: Color(0xFF34414A)),
          _row(
            'Текущая ставка',
            '${_loaderMoney(_settings?.hourlyRateMinor ?? 0)} / ч',
          ),
          _row('Удержано за месяц', _loaderMoney(deduction)),
          _row('К получению', _loaderMoney(accrued - deduction), strong: true),
          if (deduction > accrued)
            _label('Удержание превышает начисление за этот месяц.'),
          const SizedBox(height: 5),
          _label('Ставку и удержание изменяет администратор.'),
        ],
      ),
    );
  }

  Widget _form() => _panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.add_circle_outline, color: _loaderGold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _editing == null ? 'Добавить смену' : 'Изменить смену',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            if (_editing != null)
              IconButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _editing = null;
                        _hours.clear();
                        _minutes.text = '0';
                      }),
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null && mounted) setState(() => _date = date);
                },
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text('Дата: ${_loaderDate(_date)}'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _hours,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Часы',
                  hintText: '8',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _minutes,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Минуты',
                  hintText: '30',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _row(
          'За эту смену',
          _loaderMoney((_enteredMinutes * _rate / 60).round()),
          strong: true,
        ),
        if (_editing != null)
          _label('Сохранённая ставка: ${_loaderMoney(_rate)} / ч'),
        if (_rate == 0)
          _label('Попросите администратора назначить часовую ставку.'),
        const SizedBox(height: 10),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _loaderGold,
            foregroundColor: const Color(0xFF101A21),
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: _busy || _loading || _settings == null ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(_busy ? 'Сохранение…' : 'Сохранить смену'),
        ),
      ],
    ),
  );
  Widget _history() {
    final rows = _tab == 0 ? _visible.take(3).toList() : _visible;
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _tab == 0 ? 'Последние смены' : 'История смен',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_tab == 0)
                TextButton(
                  onPressed: () => setState(() => _tab = 1),
                  child: const Text('Все →'),
                ),
            ],
          ),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Text(
                'За выбранный месяц смен пока нет',
                textAlign: TextAlign.center,
                style: TextStyle(color: _loaderMuted),
              ),
            ),
          for (final s in rows)
            Column(
              children: [
                const Divider(color: Color(0xFF34414A)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: _busy ? null : () => _edit(s),
                  title: Text(
                    _loaderDate(DateTime.parse(s.day)),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${_loaderHours(s.minutes)} · ${_loaderMoney(s.amountMinor)}\nСтавка ${_loaderMoney(s.rateMinor)} / ч',
                    style: const TextStyle(color: _loaderMuted, fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    enabled: !_busy,
                    onSelected: (v) {
                      if (v == 'edit') {
                        _edit(s);
                      } else {
                        _delete(s);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Изменить')),
                      PopupMenuItem(value: 'delete', child: Text('Удалить')),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme
          .copyWith(primary: _loaderGold, secondary: _loaderGold),
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFF08131B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/scenes/cargo.png', fit: BoxFit.cover),
          const ColoredBox(color: Color(0xBA061018)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _busy
                              ? null
                              : () => _openAccountMenu(context, widget.session),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.engineering_outlined,
                                color: _loaderGold,
                                size: 30,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.session.displayName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    _label('Грузчик · Учётная запись ▾'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _busy ? null : _load,
                        icon: const Icon(Icons.refresh, color: _loaderGold),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(
                          () =>
                              _month = DateTime(_month.year, _month.month - 1),
                        ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: _pickMonth,
                          child: Text(
                            '${_loaderMonths[_month.month - 1]} ${_month.year} ▾',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(
                          () =>
                              _month = DateTime(_month.year, _month.month + 1),
                        ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 18,
                                top: 8,
                              ),
                              child: Text(
                                _tab == 0 ? 'Моя работа' : 'История',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (_error != null)
                              _panel(
                                Text(
                                  _error!,
                                  style: const TextStyle(color: _loaderGold),
                                ),
                              ),
                            if (_tab == 0)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: SizedBox(
                                  height: 150,
                                  child: Image.asset(
                                    'assets/images/scenes/cargo.png',
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    alignment: const Alignment(0, -0.1),
                                  ),
                                ),
                              ),
                            if (_tab == 0) const SizedBox(height: 14),
                            _summary(),
                            if (_tab == 0) _form(),
                            _history(),
                          ],
                        ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B24),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF47504C)),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < 2; i++)
                        Expanded(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: _tab == i
                                  ? _loaderGold
                                  : _loaderMuted,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => setState(() => _tab = i),
                            icon: Icon(i == 0 ? Icons.add_task : Icons.history),
                            label: Text(i == 0 ? 'Смена' : 'История'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
