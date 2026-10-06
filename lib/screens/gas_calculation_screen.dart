part of 'app_shell.dart';

class _GasCalculationScreen extends StatefulWidget {
  const _GasCalculationScreen();
  @override
  State<_GasCalculationScreen> createState() => _GasCalculationScreenState();
}

class _GasCalculationScreenState extends State<_GasCalculationScreen>
    with WidgetsBindingObserver {
  static const gold = _CinematicMore.gold;
  static const muted = Color(0xFFB1B4B4);
  static const _rateKey = 'gas_calculator_rate_v1';
  static const _tankKey = 'gas_calculator_tank_v1';
  double _rate = GasCalculation.rate, _tank = GasCalculation.tank;
  bool _editingSetting = false;
  GasReport? _report;
  DateTime? _month;
  double? _firstKm;
  String _odometer = '', _manual = '', _hand = '', _error = '';
  bool _manualMode = false, _manualEdited = false, _loading = true;
  bool _replace = true, _keys = true;
  int _field = 0, _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TestStore.revision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    TestStore.revision.removeListener(_load);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final now = DateTime.now();
      final month = DateTime(now.year, now.month);
      final report = await GasReportRepository.load(month);
      final prefs = await TestPreferences.getInstance();
      final rate = prefs.getDouble(_rateKey);
      final tank = prefs.getDouble(_tankKey);
      final book = await TestStore.load();
      final shifts =
          book.shifts
              .where(
                (s) =>
                    book.inMonth(s['start'] as String, month) &&
                    TestState.mileageSource(s) == MileageSource.odometer &&
                    s['startKm'] is num,
              )
              .toList()
            ..sort(
              (a, b) => (a['start'] as String).compareTo(b['start'] as String),
            );
      if (!mounted || request != _request) return;
      setState(() {
        if (_month != month) {
          _odometer = '';
          _hand = '';
          _manualEdited = false;
        }
        _month = month;
        _report = report;
        _rate = rate != null && rate.isFinite && rate > 0
            ? rate
            : GasCalculation.rate;
        _tank = tank != null && tank.isFinite && tank >= 0
            ? tank
            : GasCalculation.tank;
        _firstKm = shifts.isEmpty
            ? null
            : (shifts.first['startKm'] as num).toDouble();
        if (!_manualEdited) _manual = _plain(report.km);
        if (_firstKm == null) _manualMode = true;
        _loading = false;
        _error = '';
      });
    } catch (_) {
      if (mounted && request == _request)
        setState(() {
          _loading = false;
          _error = 'Не удалось загрузить данные. Повторите попытку.';
        });
    }
  }

  String _plain(double value) => value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'\.?0+$'), '')
      .replaceAll('.', ',');
  String _number(double value) {
    final parts = _plain(value).split(',');
    parts[0] = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return parts.join(',');
  }

  String _litres(double? value) => value == null ? '—' : '${_number(value)} л';
  double? get _distance {
    if (_manualMode) return GasCalculation.parse(_manual);
    final current = GasCalculation.parse(_odometer);
    if (current == null || _firstKm == null || current < _firstKm!) return null;
    return current - _firstKm!;
  }

  String get _input =>
      _field == 1 ? _hand : (_manualMode ? _manual : _odometer);
  void _select(int field) => setState(() {
    _field = field;
    _replace = true;
    _keys = true;
  });
  void _key(String key) {
    setState(() {
      var value = _input;
      if (key == '⌫') {
        value = value.isEmpty ? '' : value.substring(0, value.length - 1);
      } else if (key == 'C') {
        value = '';
      } else {
        if (_replace) value = '';
        if (key == ',') {
          if (value.contains(',')) return;
          value = value.isEmpty ? '0,' : '$value,';
        } else {
          value = value == '0' ? key : '$value$key';
        }
        if (GasCalculation.parse(value) == null) return;
      }
      _replace = false;
      if (_field == 1) {
        _hand = value;
      } else if (_manualMode) {
        _manual = value;
        _manualEdited = true;
      } else {
        _odometer = value;
      }
    });
  }

  Widget _line(String label, String value, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: strong ? Colors.white : muted,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: strong ? gold : Colors.white,
              fontSize: strong ? 18 : 14,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _panel(Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: _GasMetalSurface(padding: const EdgeInsets.all(13), child: child),
  );
  Widget _inputTile(
    int field,
    String label,
    String value,
    String unit,
  ) => Expanded(
    child: Semantics(
      button: true,
      label: '$label, ${value.isEmpty ? "не введено" : value} $unit',
      child: InkWell(
        onTap: () => _select(field),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0x88121618),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _field == field && _keys ? gold : const Color(0xFF494A43),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: muted, fontSize: 11)),
              const SizedBox(height: 5),
              Text(
                '${value.isEmpty ? "—" : value} $unit',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _settingLine(String label, String value, bool rate) => Semantics(
    button: true,
    label: '$label, $value. Удерживайте для изменения',
    child: InkWell(
      onLongPress: () => _editSetting(rate),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Удерживайте строку, чтобы изменить значение'),
          duration: Duration(seconds: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: _line(label, value),
      ),
    ),
  );

  Future<void> _editSetting(bool rate) async {
    if (_editingSetting) return;
    _editingSetting = true;
    HapticFeedback.selectionClick();
    final controller = TextEditingController(
      text: _plain(rate ? _rate : _tank),
    );
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    String? error;
    bool saving = false;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialog) => StatefulBuilder(
          builder: (dialog, update) => AlertDialog(
            backgroundColor: const Color(0xFF141A1C),
            title: Text(
              rate ? 'Расход, л / 100 км' : 'Газ в баке, л',
              style: const TextStyle(color: gold, fontSize: 18),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              enabled: !saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                errorText: error,
                helperText: 'Настройка только для калькулятора',
                helperMaxLines: 2,
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialog),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: saving
                    ? null
                    : () async {
                        final value = GasCalculation.parse(
                          controller.text.trim(),
                        );
                        if (value == null || (rate && value <= 0)) {
                          update(
                            () => error = rate
                                ? 'Введите расход больше нуля'
                                : 'Введите число от нуля',
                          );
                          return;
                        }
                        update(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          final prefs = await TestPreferences.getInstance();
                          final saved = await prefs.setDouble(
                            rate ? _rateKey : _tankKey,
                            value,
                          );
                          if (!saved) throw StateError('Не сохранено');
                          if (mounted)
                            setState(() {
                              if (rate) {
                                _rate = value;
                              } else {
                                _tank = value;
                              }
                            });
                          if (dialog.mounted) Navigator.pop(dialog);
                        } catch (_) {
                          if (dialog.mounted)
                            update(() {
                              saving = false;
                              error = 'Не удалось сохранить. Повторите.';
                            });
                        }
                      },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      );
    } finally {
      // Wait for the dialog's exit animation before releasing its controller.
      Future<void>.delayed(
        const Duration(milliseconds: 300),
        controller.dispose,
      );
      _editingSetting = false;
    }
  }

  Widget _content(GasReport r) {
    final entered = GasCalculation.parse(_odometer);
    final badOdometer =
        !_manualMode &&
        entered != null &&
        _firstKm != null &&
        entered < _firstKm!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      children: [
        _panel(
          Column(
            children: [
              _settingLine('Расход', '${_number(_rate)} л / 100 км', true),
              _settingLine('В баке', _litres(_tank), false),
              const Divider(color: Color(0x445F625D), height: 12),
              _line(
                'Газ за месяц',
                _litres(r.opening == null ? null : r.opening! + r.gas),
                strong: true,
              ),
              if (r.opening == null)
                const Text(
                  'Начальный остаток не задан в «Отчёте за газ». '
                  'Без него итог недоступен.',
                  style: TextStyle(color: gold, fontSize: 12),
                ),
            ],
          ),
        ),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final manual in [false, true])
                    Expanded(
                      child: TextButton(
                        onPressed: () => setState(() {
                          _manualMode = manual;
                          _field = 0;
                          _replace = true;
                          _keys = true;
                        }),
                        style: TextButton.styleFrom(
                          foregroundColor: _manualMode == manual ? gold : muted,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 36),
                          backgroundColor: _manualMode == manual
                              ? const Color(0x225F5136)
                              : Colors.transparent,
                        ),
                        child: Text(
                          manual ? 'Пробег вручную' : 'По одометру',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              _line(
                _manualMode ? 'Из журнала за месяц' : 'Первое показание месяца',
                _manualMode
                    ? '${_number(r.km)} км'
                    : _firstKm == null
                    ? 'Нет показания'
                    : '${_number(_firstKm!)} км',
              ),
              if (!_manualMode && _firstKm == null)
                const Text(
                  'Используйте «Пробег вручную».',
                  style: TextStyle(color: gold, fontSize: 12),
                ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _inputTile(
                    0,
                    _manualMode ? 'Пробег' : 'Текущий одометр',
                    _manualMode ? _manual : _odometer,
                    'км',
                  ),
                  const SizedBox(width: 8),
                  _inputTile(1, 'Газ на руках', _hand, 'л'),
                ],
              ),
              if (badOdometer)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Текущий одометр меньше первого показания.',
                    style: TextStyle(color: Color(0xFFD49A86), fontSize: 12),
                  ),
                ),
              if (_manualMode && _manualEdited)
                TextButton(
                  onPressed: () => setState(() {
                    _manual = _plain(r.km);
                    _manualEdited = false;
                    _replace = true;
                  }),
                  child: const Text(
                    'Подставить пробег из журнала',
                    style: TextStyle(color: gold, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _result(GasReport r) {
    final km = _distance;
    final hand = GasCalculation.parse(_hand);
    final calculation = r.opening != null && km != null && hand != null
        ? GasCalculation(
            opening: r.opening!,
            received: r.gas,
            distance: km,
            onHand: hand,
            consumptionRate: _rate,
            tankLitres: _tank,
          )
        : null;
    final diff = calculation?.difference;
    final result = diff == null
        ? 'Заполните данные для расчёта'
        : diff == 0
        ? '✓ По норме'
        : diff > 0
        ? 'Излишек: +${_number(diff)} л'
        : 'Недостача: −${_number(-diff)} л';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Фактический − расчётный остаток',
              style: TextStyle(color: muted, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Text(
              result,
              style: TextStyle(
                color: diff == null
                    ? muted
                    : diff < 0
                    ? const Color(0xFFD49A86)
                    : gold,
                fontSize: diff == null ? 16 : 23,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _keyboard() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
    child: _GasMetalSurface(
      compact: true,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _field == 1
                      ? 'Газ на руках, л'
                      : _manualMode
                      ? 'Пробег, км'
                      : 'Текущий одометр, км',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ),
              TextButton(
                onPressed: () => _key('C'),
                child: const Text(
                  'Очистить',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ),
              IconButton(
                tooltip: 'Скрыть клавиатуру',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _keys = false),
                icon: const Icon(
                  Icons.keyboard_hide_outlined,
                  color: gold,
                  size: 20,
                ),
              ),
            ],
          ),
          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            [',', '0', '⌫'],
          ])
            Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: OutlinedButton(
                        onPressed: () => _key(key),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: key == '⌫' ? gold : Colors.white,
                          backgroundColor: const Color(0xA0232828),
                          side: const BorderSide(color: Color(0xFF4C4B42)),
                          minimumSize: const Size(0, 38),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: Text(key, style: const TextStyle(fontSize: 21)),
                      ),
                    ),
                  ),
              ],
            ),
        ],
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
      backgroundColor: const Color(0xFF080E12),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _CinematicMore.backdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Назад',
                        icon: const Icon(Icons.arrow_back, color: gold),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Расчёт газа',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_month != null)
                              Text(
                                '${_garageMonths[_month!.month - 1]} ${_month!.year}',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _load,
                        tooltip: 'Обновить данные',
                        icon: const Icon(Icons.refresh, color: gold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: gold),
                        )
                      : _error.isNotEmpty
                      ? Center(
                          child: TextButton(
                            onPressed: _load,
                            child: Text(_error),
                          ),
                        )
                      : _report == null
                      ? const SizedBox.shrink()
                      : _content(_report!),
                ),
                if (!_loading && _error.isEmpty && _report != null)
                  _result(_report!),
                if (_keys && !_loading && _error.isEmpty) _keyboard(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
