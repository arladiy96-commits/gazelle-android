part of 'app_shell.dart';

class _GasCalculationScreen extends StatefulWidget {
  const _GasCalculationScreen();

  @override
  State<_GasCalculationScreen> createState() => _GasCalculationScreenState();
}

class _GasCalculationScreenState extends State<_GasCalculationScreen>
    with WidgetsBindingObserver {
  static const gold = Color(0xFFCEA15B);
  static const goldBright = Color(0xFFE6B46B);
  static const ink = Color(0xFF0B1013);
  static const muted = Color(0xFF90999E);
  static const white = Color(0xFFEAEDEF);
  static const danger = Color(0xFFE0715E);
  static const calm = Color(0xFF5CC3D8);

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
      final book = await TestStore.load();
      final rate = (book.calculationSettings['gasCalculatorRate'] as num?)
          ?.toDouble();
      final tank = (book.calculationSettings['gasTank'] as num?)?.toDouble();
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
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = 'Не удалось загрузить данные. Повторите попытку.';
        });
      }
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
    HapticFeedback.lightImpact();
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

  GasCalculation? _calculation(GasReport r) {
    final km = _distance;
    final hand = GasCalculation.parse(_hand);
    if (r.opening == null || km == null || hand == null) return null;
    return GasCalculation(
      opening: r.opening!,
      received: r.gas,
      distance: km,
      onHand: hand,
      consumptionRate: _rate,
      tankLitres: _tank,
    );
  }

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
            backgroundColor: const Color(0xFF10171B),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFF806844), width: .9),
            ),
            title: Text(
              rate ? 'Расход, л / 100 км' : 'Газ в баке, л',
              style: const TextStyle(color: goldBright, fontSize: 18),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              enabled: !saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: white),
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
                          await TestStore.setCalculationSetting(
                            rate ? 'gasCalculatorRate' : 'gasTank',
                            value,
                          );
                          if (mounted) {
                            setState(() {
                              if (rate) {
                                _rate = value;
                              } else {
                                _tank = value;
                              }
                            });
                          }
                          if (dialog.mounted) Navigator.pop(dialog);
                        } catch (_) {
                          if (dialog.mounted) {
                            update(() {
                              saving = false;
                              error = 'Не удалось сохранить. Повторите.';
                            });
                          }
                        }
                      },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      );
    } finally {
      Future<void>.delayed(
        const Duration(milliseconds: 300),
        controller.dispose,
      );
      _editingSetting = false;
    }
  }

  // The texture contains no data: every value and control below is live.
  // Coordinates follow the approved 864 x 1536 reference.
  Widget _scene(GasReport? r) => LayoutBuilder(
    builder: (context, box) {
      final scale = box.maxWidth / 864;
      // Reserve the system inset for the whole artwork, not just its labels.
      final topShift = math.max(
        0.0,
        MediaQuery.paddingOf(context).top - 56 * scale,
      );
      final sceneHeight = math.max(box.maxHeight, 1536 * scale + topShift);
      // Header buttons and the tank/gauge section use uniform scaling.
      // Extra screen height belongs to the rectangular panels and keyboard.
      final flexibleScale = (sceneHeight - topShift - 515 * scale) / 1021;
      final sy = scale;
      final safeBottom = MediaQuery.paddingOf(context).bottom / flexibleScale;
      const headerY = 68.0;
      double sceneY(double y) {
        if (y <= 180) return topShift + y * scale;
        final panelsTop = topShift + 180 * scale;
        if (y <= 680) return panelsTop + (y - 180) * flexibleScale;
        final tanksTop = panelsTop + 500 * flexibleScale;
        if (y <= 1015) return tanksTop + (y - 680) * scale;
        return tanksTop + 335 * scale + (y - 1015) * flexibleScale;
      }

      Widget backgroundSlice(double start, double end) {
        final sliceScale = (sceneY(end) - sceneY(start)) / (end - start);
        return Positioned(
          left: 0,
          right: 0,
          top: sceneY(start),
          height: sceneY(end) - sceneY(start),
          child: ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: -start * sliceScale,
                  height: 1536 * sliceScale,
                  child: Image.asset(
                    'assets/images/scenes/gas_calculation_reference.png',
                    fit: BoxFit.fill,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final calculation = r == null ? null : _calculation(r);
      final diff = calculation?.difference;
      final accent = diff == null
          ? gold
          : diff < 0
          ? danger
          : diff == 0
          ? calm
          : goldBright;
      final caption = diff == null
          ? 'РАСЧЁТ'
          : diff < 0
          ? 'НЕДОСТАЧА'
          : diff == 0
          ? 'ПО НОРМЕ'
          : 'ИЗЛИШЕК';
      final result = diff == null
          ? '—'
          : diff == 0
          ? '0 л'
          : diff > 0
          ? '+${_number(diff)} л'
          : '−${_number(-diff)} л';
      final entered = GasCalculation.parse(_odometer);
      final badOdometer =
          !_manualMode &&
          entered != null &&
          _firstKm != null &&
          entered < _firstKm!;
      final warning = r?.opening == null
          ? 'Укажите начальный остаток в «Отчёте за газ».'
          : badOdometer
          ? 'Текущий одометр меньше первого показания месяца.'
          : !_manualMode && _firstKm == null
          ? 'Нет стартового показания — используйте «Пробег вручную».'
          : '';
      Widget at(double x, double y, double w, double h, Widget child) =>
          Positioned(
            left: x * scale,
            top: sceneY(y),
            width: w * scale,
            height: sceneY(y + h) - sceneY(y),
            child: child,
          );
      Widget text(
        String value,
        double size, {
        Color color = white,
        bool bold = false,
        TextAlign align = TextAlign.left,
      }) => Text(
        value,
        textAlign: align,
        maxLines: 2,
        style: TextStyle(
          color: color,
          fontSize: size * scale,
          height: 1.12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      );
      Widget fit(
        String value,
        double size, {
        Color color = white,
        bool bold = false,
        Alignment align = Alignment.centerLeft,
      }) => Align(
        alignment: align,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: text(value, size, color: color, bold: bold),
        ),
      );
      Widget tap(
        Widget child,
        VoidCallback? action, {
        VoidCallback? hold,
        String? label,
      }) => Semantics(
        button: action != null || hold != null,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: action,
            onLongPress: hold,
            borderRadius: BorderRadius.circular(8),
            splashColor: gold.withValues(alpha: .12),
            child: child,
          ),
        ),
      );
      Widget stat(
        IconData icon,
        String title,
        String value, {
        VoidCallback? hold,
      }) => tap(
        Row(
          children: [
            SizedBox(
              width: 70 * scale,
              child: Icon(icon, color: goldBright, size: 44 * scale),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  text(title, 21, color: const Color(0xFFBDC3C5)),
                  SizedBox(height: 5 * sy),
                  Flexible(child: fit(value, 34, bold: true)),
                ],
              ),
            ),
          ],
        ),
        hold == null
            ? null
            : () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Удерживайте показатель, чтобы изменить значение',
                  ),
                  duration: Duration(seconds: 2),
                ),
              ),
        hold: hold,
        label:
            '$title, $value${hold == null ? "" : ". Удерживайте для изменения"}',
      );
      Widget mode(bool manual) {
        final selected = _manualMode == manual;
        return tap(
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10 * scale),
              color: selected
                  ? gold.withValues(alpha: .13)
                  : Colors.transparent,
              border: selected
                  ? Border.all(color: gold.withValues(alpha: .8), width: 1)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  manual ? Icons.edit_outlined : Icons.speed_rounded,
                  size: 31 * scale,
                  color: selected ? goldBright : muted,
                ),
                SizedBox(width: 14 * scale),
                Flexible(
                  child: fit(
                    manual ? 'Пробег вручную' : 'По одометру',
                    26,
                    color: selected ? goldBright : muted,
                  ),
                ),
              ],
            ),
          ),
          () {
            HapticFeedback.selectionClick();
            setState(() {
              _manualMode = manual;
              _field = 0;
              _replace = true;
              _keys = true;
            });
          },
          label: manual ? 'Пробег вручную' : 'По одометру',
        );
      }

      Widget input(int field, String value, String unit) => tap(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14 * scale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8 * scale),
            border: _field == field && _keys
                ? Border.all(color: goldBright.withValues(alpha: .85))
                : null,
          ),
          child: fit(
            '${value.isEmpty ? "—" : value} $unit',
            36,
            bold: true,
            align: Alignment.center,
          ),
        ),
        () => _select(field),
        label:
            '${field == 1
                ? "Газ на руках"
                : _manualMode
                ? "Пробег"
                : "Текущий одометр"}, $value $unit',
      );
      Widget key(String value) => tap(
        Center(
          child: value == '⌫'
              ? Icon(
                  Icons.backspace_outlined,
                  color: goldBright,
                  size: 39 * scale,
                )
              : fit(
                  value,
                  38,
                  color: value == 'C' ? goldBright : white,
                  bold: true,
                  align: Alignment.center,
                ),
        ),
        () => _key(value),
        label: value == '⌫'
            ? 'Удалить символ'
            : value == 'C'
            ? 'Очистить'
            : value,
      );
      final keyboardBottom = math.min(1453.0, 1536 - safeBottom - 12);
      final keyRatio = (keyboardBottom - 1168) / 285;
      Widget keyAt(double x, double y, double w, String value) =>
          at(x, 1168 + (y - 1168) * keyRatio, w, 62 * keyRatio, key(value));
      return SingleChildScrollView(
        physics: sceneHeight > box.maxHeight
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        child: SizedBox(
          height: sceneHeight,
          width: box.maxWidth,
          child: Stack(
            children: [
              Positioned.fill(
                child: ColorFiltered(
                  // Same graphite / warm metal matrix used by the gas report panels.
                  colorFilter: const ColorFilter.matrix([
                    .84,
                    .12,
                    .04,
                    0,
                    0,
                    .08,
                    .70,
                    .06,
                    0,
                    0,
                    .04,
                    .40,
                    .24,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: Stack(
                    children: [
                      // The roof also fills the physical status-bar area.
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/scenes/gas_calculation_reference.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                      backgroundSlice(0, 180),
                      backgroundSlice(180, 680),
                      backgroundSlice(680, 1015),
                      backgroundSlice(1015, 1536),
                    ],
                  ),
                ),
              ),
              at(
                94,
                headerY,
                78,
                78,
                tap(
                  Icon(
                    Icons.arrow_back_rounded,
                    color: goldBright,
                    size: 43 * scale,
                  ),
                  () => Navigator.pop(context),
                  label: 'Назад',
                ),
              ),
              at(
                692,
                headerY,
                78,
                78,
                tap(
                  Icon(
                    Icons.refresh_rounded,
                    color: goldBright,
                    size: 43 * scale,
                  ),
                  _load,
                  label: 'Обновить данные',
                ),
              ),
              at(192, headerY + 4, 478, 52, fit('Расчёт газа', 48, bold: true)),
              at(
                194,
                headerY + 56,
                470,
                28,
                fit(
                  _month == null
                      ? ''
                      : '${_garageMonths[_month!.month - 1]} ${_month!.year}',
                  25,
                  color: const Color(0xFFBDC3C5),
                ),
              ),
              if (_loading || _error.isNotEmpty || r == null)
                at(
                  100,
                  192,
                  650,
                  178,
                  Container(
                    color: ink.withValues(alpha: .85),
                    alignment: Alignment.center,
                    child: _loading
                        ? const CircularProgressIndicator(color: gold)
                        : tap(
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: text(
                                _error.isEmpty ? 'Нет данных' : _error,
                                26,
                              ),
                            ),
                            _load,
                          ),
                  ),
                )
              else ...[
                at(
                  139,
                  194,
                  291,
                  85,
                  stat(
                    Icons.propane_tank_outlined,
                    'Остаток\nс прошлого месяца',
                    _litres(r.opening),
                  ),
                ),
                at(
                  463,
                  194,
                  269,
                  85,
                  stat(
                    Icons.local_shipping_outlined,
                    'Получено\nза месяц',
                    _litres(r.gas),
                  ),
                ),
                at(
                  139,
                  296,
                  291,
                  73,
                  stat(
                    Icons.speed_rounded,
                    'Норма расхода',
                    '${_number(_rate)} л / 100 км',
                    hold: () => _editSetting(true),
                  ),
                ),
                at(
                  463,
                  296,
                  269,
                  73,
                  stat(
                    Icons.local_gas_station_outlined,
                    'В баке',
                    _litres(_tank),
                    hold: () => _editSetting(false),
                  ),
                ),
                at(109, 413, 316, 54, mode(false)),
                at(441, 413, 309, 54, mode(true)),
                at(
                  140,
                  477,
                  586,
                  29,
                  fit(
                    _manualMode
                        ? 'Из журнала за месяц   ${_number(r.km)} км'
                        : 'Первое показание месяца   ${_firstKm == null ? "Нет показания" : "${_number(_firstKm!)} км"}',
                    23,
                    color: const Color(0xFFBDC3C5),
                    align: Alignment.center,
                  ),
                ),
                at(
                  126,
                  509,
                  612,
                  23,
                  _manualMode && _manualEdited
                      ? tap(
                          fit(
                            '↶ Подставить пробег из журнала',
                            20,
                            color: goldBright,
                            align: Alignment.center,
                          ),
                          () => setState(() {
                            _manual = _plain(r.km);
                            _manualEdited = false;
                            _replace = true;
                          }),
                        )
                      : fit(
                          'Это значение используется только для текущего расчёта.',
                          17,
                          color: muted,
                          align: Alignment.center,
                        ),
                ),
                at(
                  128,
                  549,
                  36,
                  29,
                  Icon(
                    Icons.add_road_rounded,
                    color: goldBright,
                    size: 31 * scale,
                  ),
                ),
                at(
                  181,
                  549,
                  229,
                  29,
                  fit(
                    _manualMode ? 'Пробег' : 'Текущий одометр',
                    23,
                    color: const Color(0xFFBDC3C5),
                  ),
                ),
                at(
                  460,
                  549,
                  36,
                  29,
                  Icon(
                    Icons.local_gas_station_outlined,
                    color: goldBright,
                    size: 31 * scale,
                  ),
                ),
                at(
                  514,
                  549,
                  221,
                  29,
                  fit('Газ на руках', 23, color: const Color(0xFFBDC3C5)),
                ),
                at(
                  124,
                  588,
                  284,
                  48,
                  input(0, _manualMode ? _manual : _odometer, 'км'),
                ),
                at(458, 588, 281, 48, input(1, _hand, 'л')),
                // Preserve selection from anywhere on either input card.
                at(
                  109,
                  539,
                  316,
                  107,
                  ExcludeSemantics(
                    child: tap(const SizedBox.expand(), () => _select(0)),
                  ),
                ),
                at(
                  441,
                  539,
                  309,
                  107,
                  ExcludeSemantics(
                    child: tap(const SizedBox.expand(), () => _select(1)),
                  ),
                ),
                at(
                  145,
                  746,
                  150,
                  46,
                  fit(
                    'Должно\ностаться',
                    23,
                    color: const Color(0xFFBDC3C5),
                    align: Alignment.center,
                  ),
                ),
                at(
                  148,
                  802,
                  139,
                  48,
                  fit(
                    calculation == null ? '—' : _litres(calculation.expected),
                    43,
                    color: const Color(0xFFF0D8A7),
                    bold: true,
                    align: Alignment.center,
                  ),
                ),
                at(
                  596,
                  749,
                  151,
                  46,
                  fit(
                    'Фактически',
                    23,
                    color: const Color(0xFFBDC3C5),
                    align: Alignment.center,
                  ),
                ),
                at(
                  601,
                  802,
                  133,
                  48,
                  fit(
                    calculation == null ? '—' : _litres(calculation.actual),
                    43,
                    color: const Color(0xFFF0D8A7),
                    bold: true,
                    align: Alignment.center,
                  ),
                ),
                at(
                  347,
                  815,
                  174,
                  35,
                  fit(
                    caption,
                    24,
                    color: accent,
                    bold: true,
                    align: Alignment.center,
                  ),
                ),
                at(
                  337,
                  854,
                  197,
                  67,
                  fit(
                    result,
                    70,
                    color: accent,
                    bold: true,
                    align: Alignment.center,
                  ),
                ),
                at(
                  404,
                  928,
                  58,
                  59,
                  Icon(
                    Icons.local_fire_department_outlined,
                    color: accent,
                    size: 57 * scale,
                  ),
                ),
                at(
                  112,
                  1040,
                  48,
                  50,
                  Icon(
                    Icons.calculate_outlined,
                    color: goldBright,
                    size: 45 * scale,
                  ),
                ),
                at(
                  190,
                  1038,
                  515,
                  28,
                  fit(
                    'Фактически = Газ на руках + ${_number(_tank)} л в баке',
                    20,
                    color: const Color(0xFFBDC3C5),
                  ),
                ),
                at(
                  190,
                  1068,
                  515,
                  28,
                  fit(
                    'Расчётный остаток = Остаток + Получено − Расход по норме',
                    19,
                    color: const Color(0xFFBDC3C5),
                  ),
                ),
                at(
                  720,
                  1040,
                  48,
                  50,
                  Tooltip(
                    message:
                        'Расход по норме = пробег × ${_number(_rate)} / 100',
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: muted,
                      size: 29 * scale,
                    ),
                  ),
                ),
                if (warning.isNotEmpty)
                  at(
                    120,
                    1102,
                    627,
                    25,
                    Container(
                      color: ink.withValues(alpha: .93),
                      child: fit(
                        warning,
                        19,
                        color: badOdometer ? danger : gold,
                        align: Alignment.center,
                      ),
                    ),
                  ),
                if (_keys) ...[
                  keyAt(141, 1168, 133, '1'),
                  keyAt(290, 1168, 134, '2'),
                  keyAt(442, 1168, 135, '3'),
                  keyAt(594, 1168, 130, '⌫'),
                  keyAt(136, 1240, 136, '4'),
                  keyAt(287, 1240, 137, '5'),
                  keyAt(441, 1240, 138, '6'),
                  keyAt(595, 1240, 133, 'C'),
                  keyAt(131, 1314, 140, '7'),
                  keyAt(286, 1314, 140, '8'),
                  keyAt(442, 1314, 140, '9'),
                  keyAt(127, 1390, 144, ','),
                  keyAt(286, 1390, 297, '0'),
                  at(
                    600,
                    1314,
                    136,
                    137,
                    tap(
                      Icon(
                        Icons.keyboard_hide_outlined,
                        size: 30 * scale,
                        color: muted,
                      ),
                      () {
                        HapticFeedback.lightImpact();
                        setState(() => _keys = false);
                      },
                      label: 'Скрыть клавиатуру',
                    ),
                  ),
                ] else
                  at(
                    127,
                    1168,
                    609,
                    283,
                    tap(
                      Container(
                        color: ink.withValues(alpha: .93),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.dialpad_rounded,
                              color: gold,
                              size: 48 * scale,
                            ),
                            SizedBox(height: 12 * sy),
                            text('Показать клавиатуру', 25, color: gold),
                          ],
                        ),
                      ),
                      () => _select(_field),
                      label: 'Показать клавиатуру',
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    },
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
      backgroundColor: ink,
      resizeToAvoidBottomInset: false,
      body: _scene(_report),
    ),
  );
}
