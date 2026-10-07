part of 'app_shell.dart';

class _CalculationSettingsScreen extends StatefulWidget {
  final String? group;
  final bool settingsRoot;
  const _CalculationSettingsScreen({this.group, this.settingsRoot = false});
  @override
  State<_CalculationSettingsScreen> createState() =>
      _CalculationSettingsScreenState();
}

class _CalculationSettingsScreenState
    extends State<_CalculationSettingsScreen> {
  static const gold = _CinematicMore.gold, muted = Color(0xFFB1B4B4);
  static const groups = [
    'Зарплата',
    'Рабочий календарь',
    'Направления и суточные',
    'Газ',
    'Обслуживание',
  ];
  static const fields = <String, List<(String, String, String)>>{
    'Зарплата': [
      ('salary.base', 'Основной оклад', '₸ / месяц'),
      ('salary.weekend', 'Выходной', '₸ / день'),
      ('salary.holiday', 'Праздник', '₸ / день'),
      ('salary.paid', 'Платный рейс', '₸ / рейс'),
      ('salary.city', 'Городской вес', '₸ / кг'),
      ('salary.region', 'Районный вес', '₸ / кг'),
    ],
    'Рабочий календарь': [
      ('workdays', 'Рабочие дни недели', '1 — пн, 7 — вс'),
      ('hoursPerDay', 'Часов в рабочем дне', 'ч'),
      ('holidays', 'Праздничные даты', 'ГГГГ-ММ-ДД'),
      ('workingDates', 'Переносы: рабочие даты', 'ГГГГ-ММ-ДД'),
      ('restDates', 'Переносы: выходные даты', 'ГГГГ-ММ-ДД'),
      (
        'stackHoliday',
        'Складывать выходной и праздник',
        'Иначе только праздничная выплата',
      ),
      (
        'payOverNorm',
        'Оплачивать часы сверх нормы',
        'По ставке оклад ÷ норма месяца',
      ),
    ],
    'Направления и суточные': [
      ('paidDirections', 'Платные направления', 'По одному названию в строке'),
      (
        'allowanceDirections',
        'Направления с суточными',
        'По одному названию в строке',
      ),
      ('allowance', 'Размер суточных', '₸'),
      (
        'allowancePerDay',
        'Суточные один раз за день',
        'Выключено — за каждую подходящую поездку',
      ),
    ],
    'Газ': [
      ('gasReportRate', 'Норма отчёта за газ', 'л / 100 км'),
      ('gasCalculatorRate', 'Норма калькулятора', 'л / 100 км'),
      ('gasTank', 'Газ в баке для калькулятора', 'л'),
    ],
  };
  bool busy = false;
  String show(Object? value) {
    if (value is bool) return value ? 'Включено' : 'Выключено';
    if (value is List) return value.isEmpty ? 'Не задано' : value.join(', ');
    if (value is num)
      return value
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'\.?0+$'), '')
          .replaceAll('.', ',');
    return '$value';
  }

  List<(String, String, String)> entries(String group) =>
      group == 'Обслуживание'
      ? [
          for (final item in MaintenanceCatalog.items)
            (
              'maintenance.${item.id}',
              item.title,
              item.usesDate
                  ? 'дней · 0 — без интервала'
                  : 'км · 0 — без интервала',
            ),
        ]
      : fields[group] ?? [];
  String label(String key) {
    for (final g in groups) {
      for (final f in entries(g)) {
        if (f.$1 == key) return f.$2;
      }
    }
    return key;
  }

  Object value(TestState book, String key) => key.startsWith('salary.')
      ? book.currentSalaryRates[key.substring(7)]!
      : book.calculationSettings[key] ?? 0;
  Future<void> edit(TestState book, (String, String, String) field) async {
    if (busy) return;
    final key = field.$1, current = value(book, key), isList = current is List;
    final controller = TextEditingController(
      text: isList ? current.join('\n') : show(current),
    );
    Object? selected;
    String? error;
    bool toggle = current == true;
    selected = await showDialog<Object>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (c, update) => AlertDialog(
          backgroundColor: const Color(0xFF11181C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: const BorderSide(color: Color(0xFF776044), width: .8),
          ),
          titleTextStyle: const TextStyle(
            color: Color(0xFFE9EAEB),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: const TextStyle(
            color: Color(0xFF90999E),
            fontSize: 12,
          ),
          surfaceTintColor: Colors.transparent,
          title: Text(field.$2),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (current is bool)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(field.$3),
                    activeThumbColor: gold,
                    value: toggle,
                    onChanged: (v) => update(() => toggle = v),
                  )
                else
                  TextField(
                    style: const TextStyle(
                      color: Color(0xFFE9EAEB),
                      fontSize: 14,
                    ),
                    cursorColor: gold,
                    controller: controller,
                    autofocus: true,
                    maxLines: isList ? 6 : 1,
                    keyboardType: isList
                        ? TextInputType.multiline
                        : const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      helperStyle: const TextStyle(
                        color: Color(0xFF90999E),
                        fontSize: 10,
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF62605A)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: gold),
                      ),
                      helperText: field.$3,
                      errorText: error,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  key.startsWith('gasCalculator') || key == 'gasTank'
                      ? 'Применится сразу к калькулятору.'
                      : key.startsWith('maintenance.')
                      ? 'Интервал подставляется в новые записи обслуживания. Существующие сроки сохраняются.'
                      : widget.group == 'Рабочий календарь'
                      ? 'Применится к новым сменам. Нормы и условия внесённых смен сохраняются.'
                      : 'С момента сохранения. Старые записи сохраняют свои условия расчёта.',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: gold),
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Отмена'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: gold),
              onPressed: () {
                try {
                  Object v;
                  if (current is bool) {
                    v = toggle;
                  } else if (isList) {
                    final list = controller.text
                        .split(RegExp(r'[,;\n]'))
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toSet()
                        .toList();
                    v = key == 'workdays' ? list.map(int.parse).toList() : list;
                  } else {
                    final input = controller.text
                        .trim()
                        .replaceAll(' ', '')
                        .replaceAll(',', '.');
                    if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(input))
                      throw ArgumentError('Не более двух знаков после запятой');
                    v = double.parse(input);
                  }
                  if (key.startsWith('salary.')) {
                    if (v is! num || !v.isFinite || v < 0 || v > 999999999)
                      throw ArgumentError('Проверьте ставку');
                  } else
                    CalculationSettings.validate(key, v);
                  Navigator.pop(dialog, v);
                } catch (e) {
                  update(
                    () => error = e is ArgumentError
                        ? '${e.message}'
                        : 'Проверьте введённые значения',
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (!mounted || selected == null) return;
    setState(() => busy = true);
    try {
      if (key.startsWith('salary.'))
        await TestStore.setSalaryRate(
          key.substring(7),
          (selected as num).toDouble(),
        );
      else
        await TestStore.setCalculationSetting(key, selected);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Не удалось сохранить: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  IconData groupIcon(String? name) => switch (name) {
    'Зарплата' => Icons.account_balance_wallet_outlined,
    'Рабочий календарь' => Icons.calendar_month_outlined,
    'Направления и суточные' => Icons.signpost_outlined,
    'Газ' => Icons.local_gas_station_outlined,
    'Обслуживание' => Icons.handyman_outlined,
    'История изменений' => Icons.history,
    _ => Icons.calculate_outlined,
  };
  Widget panel(
    String title,
    String subtitle,
    VoidCallback? action, {
    IconData? icon,
  }) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: busy ? null : action,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            _CinematicMore.badge(icon ?? groupIcon(widget.group), gold),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFE9EAEB),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF90999E),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFBDC3C5),
                size: 19,
              ),
            ],
          ],
        ),
      ),
    ),
  );
  Widget section(String title, IconData icon, List<Widget> rows) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 7, top: 6),
          child: Row(
            children: [
              Icon(icon, color: gold, size: 19),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF7397A9),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Divider(color: Color(0xFF62605A), height: 1),
              ),
            ],
          ),
        ),
        Container(
          decoration: _CinematicMore.panel(),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: Color(0xFF353A3D)),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    ),
  );
  String get subtitle => widget.settingsRoot
      ? 'Управление приложением'
      : widget.group == null
      ? 'Ставки, нормы и правила учёта'
      : widget.group == 'История изменений'
      ? 'Сохранённые значения и даты'
      : 'Нажмите параметр для изменения';
  Widget header() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xB010161A),
            border: Border.all(color: gold),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: 'Назад',
            onPressed: busy ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.chevron_left, color: gold),
          ),
        ),
        const SizedBox(width: 17),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.settingsRoot
                    ? 'Настройки'
                    : widget.group ?? 'Параметры расчётов',
                style: const TextStyle(
                  color: Color(0xFFF1EEE6),
                  fontSize: 27,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              const SizedBox(
                width: 48,
                child: Divider(color: gold, height: 3, thickness: 1.5),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFFC1C4C5), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  void open(String? group, {bool root = false}) => Navigator.push(
    context,
    _SceneRoute<void>(
      builder: (_) =>
          _CalculationSettingsScreen(group: group, settingsRoot: root),
    ),
  );
  List<Map<String, dynamic>> history(TestState b) {
    final result = [...b.calculationHistory];
    var previous = Map<String, double>.of(SalaryRates.defaults);
    for (final e in b.salaryRateHistory) {
      final rates = SalaryRates.decode(e['rates']);
      for (final key in rates.keys) {
        if (rates[key] != previous[key])
          result.add({
            'at': e['at'],
            'key': 'salary.$key',
            'old': previous[key],
            'value': rates[key],
          });
      }
      previous = rates;
    }
    result.sort((a, b) => (b['at'] as String).compareTo(a['at'] as String));
    return result;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF080E12),
        body: Stack(
          children: [
            _CinematicMore.backdrop(),
            SafeArea(
              child: Column(
                children: [
                  header(),
                  if (busy)
                    const LinearProgressIndicator(color: gold, minHeight: 2),
                  Expanded(
                    child: _TestLive(
                      builder: (book) {
                        final events = widget.group == 'История изменений'
                            ? history(book)
                            : <Map<String, dynamic>>[];
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(22, 2, 18, 10),
                          children: [
                            if (widget.settingsRoot)
                              section('Приложение', Icons.settings_outlined, [
                                panel(
                                  'Параметры расчётов',
                                  'Ставки, календарь, газ и обслуживание',
                                  () => open(null),
                                  icon: Icons.calculate_outlined,
                                ),
                              ])
                            else if (widget.group == null) ...[
                              section('Расчёты', Icons.calculate_outlined, [
                                for (final g in groups)
                                  panel(
                                    g,
                                    switch (g) {
                                      'Зарплата' => 'Оклад, доплаты и вес',
                                      'Рабочий календарь' =>
                                        'Рабочие дни, праздники и норма часов',
                                      'Направления и суточные' =>
                                        'Платные поездки и выплаты',
                                      'Газ' => 'Нормы расхода и газ в баке',
                                      _ => 'Интервалы обслуживания',
                                    },
                                    () => open(g),
                                    icon: groupIcon(g),
                                  ),
                              ]),
                              section('Изменения', Icons.history, [
                                panel(
                                  'История изменений',
                                  'Значения и даты начала действия',
                                  () => open('История изменений'),
                                  icon: Icons.history,
                                ),
                              ]),
                            ] else if (widget.group == 'История изменений')
                              section('История', Icons.history, [
                                if (events.isEmpty)
                                  panel(
                                    'Изменений пока нет',
                                    'Здесь появятся сохранённые настройки',
                                    null,
                                    icon: Icons.history,
                                  ),
                                for (final e in events)
                                  panel(
                                    label(e['key'] as String),
                                    '${show(e['old'])} → ${show(e['value'])}\n${_detailDate(DateTime.parse(e['at'] as String))} · ${_detailTime(DateTime.parse(e['at'] as String))}',
                                    () => showDialog<void>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        backgroundColor: const Color(
                                          0xFF11181C,
                                        ),
                                        surfaceTintColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            17,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF776044),
                                            width: .8,
                                          ),
                                        ),
                                        title: Text(
                                          label(e['key'] as String),
                                          style: const TextStyle(
                                            color: Color(0xFFE9EAEB),
                                            fontSize: 16,
                                          ),
                                        ),
                                        content: SingleChildScrollView(
                                          child: Text(
                                            'Было: ${show(e['old'])}\n\nСтало: ${show(e['value'])}\n\n${_detailDate(DateTime.parse(e['at'] as String))} · ${_detailTime(DateTime.parse(e['at'] as String))}',
                                            style: const TextStyle(
                                              color: Color(0xFFC1C4C5),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              foregroundColor: gold,
                                            ),
                                            onPressed: () => Navigator.pop(c),
                                            child: const Text('Закрыть'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    icon: Icons.history,
                                  ),
                              ])
                            else ...[
                              section('Параметры', groupIcon(widget.group), [
                                for (final f in entries(widget.group!))
                                  panel(
                                    f.$2,
                                    '${show(value(book, f.$1))}\n${f.$3}',
                                    () => edit(book, f),
                                  ),
                              ]),
                              if (widget.group == 'Рабочий календарь')
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    'Праздники и переносы задаются по датам для каждого года. Новые годы автоматически не добавляются.',
                                    style: TextStyle(
                                      color: Color(0xFF90999E),
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                            ],
                          ],
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
    ),
  );
}
