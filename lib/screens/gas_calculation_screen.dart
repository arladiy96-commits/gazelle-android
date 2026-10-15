part of 'app_shell.dart';

class _GasCalculationScreen extends StatefulWidget {
  const _GasCalculationScreen();

  @override
  State<_GasCalculationScreen> createState() => _GasCalculationScreenState();
}

class _GasCalculationScreenState extends State<_GasCalculationScreen>
    with WidgetsBindingObserver {
  static const gold = Color(0xFFE0AE63);
  static const goldBright = Color(0xFFFFC66B);
  static const ink = Color(0xFF0B1013);
  static const muted = Color(0xFFA7ADB0);
  static const white = Color(0xFFF2F3F3);
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

  Widget _backdrop() => Positioned.fill(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/scenes/gas_dashboard.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: .18),
                const Color(0xFF071015).withValues(alpha: .44),
                Colors.black.withValues(alpha: .66),
              ],
              stops: const [0, .46, 1],
            ),
          ),
        ),
      ],
    ),
  );

  BoxDecoration _metalDecoration({bool active = false, Color? accent}) {
    final border = accent ?? (active ? goldBright : const Color(0xFF6F5B3C));
    return BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xF5121A1E), Color(0xF4080E12)],
      ),
      border: Border.all(color: border.withValues(alpha: active ? .95 : .72)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .55),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
        if (active || accent != null)
          BoxShadow(
            color: border.withValues(alpha: .16),
            blurRadius: 18,
            spreadRadius: 1,
          ),
      ],
    );
  }

  Widget _bolts() => IgnorePointer(
    child: Stack(
      children: const [
        Positioned(left: 8, top: 8, child: _GasCalcBolt()),
        Positioned(right: 8, top: 8, child: _GasCalcBolt()),
        Positioned(left: 8, bottom: 8, child: _GasCalcBolt()),
        Positioned(right: 8, bottom: 8, child: _GasCalcBolt()),
      ],
    ),
  );

  Widget _metalPanel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(14),
    bool active = false,
    Color? accent,
  }) => Container(
    decoration: _metalDecoration(active: active, accent: accent),
    child: Stack(
      children: [
        Padding(padding: padding, child: child),
        Positioned.fill(child: _bolts()),
      ],
    ),
  );

  Widget _roundButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) => Semantics(
    button: true,
    label: tooltip,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xEE0C1215),
          border: Border.all(color: gold.withValues(alpha: .9), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: gold.withValues(alpha: .14),
              blurRadius: 15,
            ),
          ],
        ),
        child: Icon(icon, color: goldBright, size: 29),
      ),
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
    child: Row(
      children: [
        _roundButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Назад',
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Расчёт газа',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: white,
                  fontSize: 29,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 5),
              if (_month != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_garageMonths[_month!.month - 1]} ${_month!.year}',
                      style: const TextStyle(
                        color: Color(0xFFD4D7D9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 17,
                      color: gold,
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _roundButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Обновить данные',
          onTap: _load,
        ),
      ],
    ),
  );

  Widget _summaryCell({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onLongPress,
  }) => Semantics(
    button: onLongPress != null,
    label: onLongPress == null ? '$label, $value' : '$label, $value. Удерживайте для изменения',
    child: InkWell(
      onLongPress: onLongPress,
      onTap: onLongPress == null
          ? null
          : () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Удерживайте показатель, чтобы изменить значение'),
                duration: Duration(seconds: 2),
              ),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: goldBright, size: 27),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD1D4D5),
                      fontSize: 12,
                      height: 1.14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: white,
                      fontSize: 20,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _summary(GasReport r) => _metalPanel(
    padding: const EdgeInsets.fromLTRB(11, 11, 11, 10),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCell(
                icon: Icons.inventory_2_outlined,
                label: 'Остаток\nс прошлого месяца',
                value: _litres(r.opening),
              ),
            ),
            Container(width: 1, height: 66, color: const Color(0xFF4F5150)),
            Expanded(
              child: _summaryCell(
                icon: Icons.local_shipping_outlined,
                label: 'Получено\nза месяц',
                value: _litres(r.gas),
              ),
            ),
          ],
        ),
        Container(height: 1, color: const Color(0xFF4F5150)),
        Row(
          children: [
            Expanded(
              child: _summaryCell(
                icon: Icons.speed_rounded,
                label: 'Норма расхода',
                value: '${_number(_rate)} л / 100 км',
                onLongPress: () => _editSetting(true),
              ),
            ),
            Container(width: 1, height: 66, color: const Color(0xFF4F5150)),
            Expanded(
              child: _summaryCell(
                icon: Icons.local_gas_station_outlined,
                label: 'В баке',
                value: _litres(_tank),
                onLongPress: () => _editSetting(false),
              ),
            ),
          ],
        ),
        if (r.opening == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline_rounded, color: gold, size: 16),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Укажите начальный остаток в «Отчёте за газ», иначе итог недоступен.',
                    style: TextStyle(color: gold, fontSize: 10.5, height: 1.25),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _modeButton(bool manual) {
    final selected = _manualMode == manual;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _manualMode = manual;
            _field = 0;
            _replace = true;
            _keys = true;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF5D401D), Color(0xFF241B10)],
                  )
                : null,
            border: Border.all(
              color: selected ? goldBright : const Color(0xFF4C565C),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: gold.withValues(alpha: .22),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                manual ? Icons.edit_outlined : Icons.speed_rounded,
                size: 20,
                color: selected ? goldBright : muted,
              ),
              const SizedBox(width: 7),
              Text(
                manual ? 'Пробег вручную' : 'По одометру',
                style: TextStyle(
                  color: selected ? goldBright : muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputCard({
    required int field,
    required IconData icon,
    required String label,
    required String value,
    required String unit,
  }) {
    final selected = _field == field && _keys;
    return Expanded(
      child: Semantics(
        button: true,
        label: '$label, ${value.isEmpty ? "не введено" : value} $unit',
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => _select(field),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.fromLTRB(11, 9, 10, 10),
            decoration: BoxDecoration(
              color: const Color(0xB50A1013),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected ? goldBright : const Color(0xFF725D3C),
                width: selected ? 1.2 : .8,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: gold.withValues(alpha: .17),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: goldBright, size: 19),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFCDD1D3), fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xC4070C0F),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFF81683F)),
                  ),
                  child: Text(
                    '${value.isEmpty ? "—" : value} $unit',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputSection(GasReport r) {
    final entered = GasCalculation.parse(_odometer);
    final badOdometer =
        !_manualMode && entered != null && _firstKm != null && entered < _firstKm!;
    return _metalPanel(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
      child: Column(
        children: [
          Row(
            children: [
              _modeButton(false),
              const SizedBox(width: 8),
              _modeButton(true),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _manualMode ? 'Из журнала за месяц' : 'Первое показание месяца',
                style: const TextStyle(color: muted, fontSize: 11.5),
              ),
              const SizedBox(width: 7),
              Text(
                _manualMode
                    ? '${_number(r.km)} км'
                    : _firstKm == null
                    ? 'Нет показания'
                    : '${_number(_firstKm!)} км',
                style: TextStyle(
                  color: _firstKm == null && !_manualMode ? danger : goldBright,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Это значение используется только для текущего расчёта.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8F989D), fontSize: 9.5),
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inputCard(
                field: 0,
                icon: Icons.add_road_rounded,
                label: _manualMode ? 'Пробег' : 'Текущий одометр',
                value: _manualMode ? _manual : _odometer,
                unit: 'км',
              ),
              const SizedBox(width: 8),
              _inputCard(
                field: 1,
                icon: Icons.local_gas_station_outlined,
                label: 'Газ на руках',
                value: _hand,
                unit: 'л',
              ),
            ],
          ),
          if (badOdometer)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Текущий одометр меньше первого показания месяца.',
                style: TextStyle(color: danger, fontSize: 10.5),
              ),
            ),
          if (!_manualMode && _firstKm == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Нет стартового показания — используйте «Пробег вручную».',
                style: TextStyle(color: gold, fontSize: 10.5),
              ),
            ),
          if (_manualMode && _manualEdited)
            TextButton.icon(
              onPressed: () => setState(() {
                _manual = _plain(r.km);
                _manualEdited = false;
                _replace = true;
              }),
              icon: const Icon(Icons.restore_rounded, color: gold, size: 15),
              label: const Text(
                'Подставить пробег из журнала',
                style: TextStyle(color: gold, fontSize: 10.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tankCard({
    required String label,
    required String value,
    required Color accent,
  }) => Expanded(
    child: Container(
      height: 118,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(52),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF242C30), Color(0xFF101619)],
        ),
        border: Border.all(color: const Color(0xFF7A6543), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFD6D9DA), fontSize: 11, height: 1.15),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: accent,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: .3), accent],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _centerGauge(GasCalculation? calculation) {
    final diff = calculation?.difference;
    final Color accent = diff == null
        ? gold
        : diff < 0
        ? danger
        : diff == 0
        ? calm
        : goldBright;
    final String caption = diff == null
        ? 'РАСЧЁТ'
        : diff < 0
        ? 'НЕДОСТАЧА'
        : diff == 0
        ? 'ПО НОРМЕ'
        : 'ИЗЛИШЕК';
    final String value = diff == null
        ? '—'
        : diff == 0
        ? '0 л'
        : diff > 0
        ? '+${_number(diff)} л'
        : '−${_number(-diff)} л';
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xF20A0F12),
        border: Border.all(color: accent, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .28),
            blurRadius: 22,
            spreadRadius: 1,
          ),
          const BoxShadow(color: Colors.black, blurRadius: 9, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            caption,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .25,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: diff == null ? muted : white,
                fontSize: 27,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Icon(Icons.local_fire_department_rounded, color: accent, size: 23),
        ],
      ),
    );
  }

  Widget _resultSection(GasReport r) {
    final calculation = _calculation(r);
    return Column(
      children: [
        SizedBox(
          height: 142,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _tankCard(
                label: 'Должно\ностаться',
                value: calculation == null ? '—' : _litres(calculation.expected),
                accent: calculation == null ? muted : const Color(0xFFF0D8A7),
              ),
              const SizedBox(width: 6),
              _centerGauge(calculation),
              const SizedBox(width: 6),
              _tankCard(
                label: 'Фактически',
                value: calculation == null ? '—' : _litres(calculation.actual),
                accent: calculation == null ? muted : const Color(0xFFF0D8A7),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _metalPanel(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              const Icon(Icons.calculate_outlined, color: goldBright, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Фактически = газ на руках + газ в баке',
                      style: TextStyle(color: Color(0xFFD4D7D9), fontSize: 10.5),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Расчётный остаток = остаток + получено − расход по норме',
                      style: TextStyle(color: Color(0xFFD4D7D9), fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.info_outline_rounded, color: muted, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _keyButton(String key, {int flex = 1}) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.all(2.5),
      child: key.isEmpty
          ? const SizedBox(height: 43)
          : OutlinedButton(
              onPressed: () => _key(key),
              style: OutlinedButton.styleFrom(
                foregroundColor: key == '⌫' || key == 'C'
                    ? goldBright
                    : white,
                backgroundColor: key == 'C'
                    ? const Color(0xFF4B3519)
                    : const Color(0xEE151B1F),
                side: BorderSide(
                  color: key == 'C'
                      ? goldBright
                      : const Color(0xFF715D3E),
                ),
                minimumSize: const Size(0, 43),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: Text(
                key,
                style: TextStyle(
                  fontSize: key == 'C' ? 17 : 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    ),
  );

  Widget _keyboard() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 7, 12, 5),
    child: _metalPanel(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
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
                  style: const TextStyle(color: muted, fontSize: 10.5),
                ),
              ),
              TextButton(
                onPressed: () => _key('C'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: gold,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('Очистить', style: TextStyle(fontSize: 10.5)),
              ),
              IconButton(
                tooltip: 'Скрыть клавиатуру',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _keys = false);
                },
                icon: const Icon(
                  Icons.keyboard_hide_outlined,
                  color: gold,
                  size: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Row(children: [_keyButton('1'), _keyButton('2'), _keyButton('3'), _keyButton('⌫')]),
          Row(children: [_keyButton('4'), _keyButton('5'), _keyButton('6'), _keyButton('C')]),
          Row(children: [_keyButton('7'), _keyButton('8'), _keyButton('9'), _keyButton('')]),
          Row(children: [_keyButton(','), _keyButton('0', flex: 2), _keyButton('')]),
        ],
      ),
    ),
  );

  Widget _body(GasReport r) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    child: Column(
      children: [
        _summary(r),
        const SizedBox(height: 8),
        _inputSection(r),
        const SizedBox(height: 10),
        _resultSection(r),
      ],
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
      backgroundColor: ink,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _backdrop(),
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: gold))
                      : _error.isNotEmpty
                      ? Center(
                          child: TextButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(_error),
                          ),
                        )
                      : _report == null
                      ? const SizedBox.shrink()
                      : _body(_report!),
                ),
                if (_keys && !_loading && _error.isEmpty && _report != null)
                  _keyboard(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _GasCalcBolt extends StatelessWidget {
  const _GasCalcBolt();

  @override
  Widget build(BuildContext context) => Container(
    width: 5,
    height: 5,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFFB89561),
      border: Border.all(color: const Color(0xFF44351F), width: .6),
      boxShadow: const [
        BoxShadow(color: Colors.black, blurRadius: 2, offset: Offset(0, 1)),
      ],
    ),
  );
}
