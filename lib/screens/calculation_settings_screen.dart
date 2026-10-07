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
      text: isList ? (current as List).join('\n') : show(current),
    );
    Object? selected;
    String? error;
    bool toggle = current == true;
    selected = await showDialog<Object>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (c, update) => AlertDialog(
          backgroundColor: const Color(0xFF161A1C),
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
                    value: toggle,
                    onChanged: (v) => update(() => toggle = v),
                  )
                else
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLines: isList ? 6 : 1,
                    keyboardType: isList
                        ? TextInputType.multiline
                        : const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
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
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Отмена'),
            ),
            TextButton(
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

  Widget panel(
    String title,
    String subtitle,
    VoidCallback action, {
    IconData icon = Icons.chevron_right,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: _GasMetalSurface(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: busy ? null : action,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: gold, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: gold, size: 20),
          ],
        ),
      ),
    ),
  );
  void open(String? group, {bool root = false}) => Navigator.push(
    context,
    MaterialPageRoute<void>(
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
    child: Scaffold(
      backgroundColor: const Color(0xFF101517),
      body: Stack(
        children: [
          _CinematicMore.backdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: busy ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: gold),
                      ),
                      Expanded(
                        child: Text(
                          widget.settingsRoot
                              ? 'Настройки'
                              : widget.group ?? 'Параметры расчётов',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  const LinearProgressIndicator(color: gold, minHeight: 2),
                Expanded(
                  child: _TestLive(
                    builder: (book) => ListView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      children: [
                        if (widget.settingsRoot)
                          panel(
                            'Параметры расчётов',
                            'Ставки, календарь, газ и обслуживание',
                            () => open(null),
                            icon: Icons.calculate_outlined,
                          )
                        else if (widget.group == null) ...[
                          for (final g in groups) panel(g, '', () => open(g)),
                          panel(
                            'История изменений',
                            'Значения и даты начала действия',
                            () => open('История изменений'),
                            icon: Icons.history,
                          ),
                        ] else if (widget.group == 'История изменений') ...[
                          if (history(book).isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Изменений пока нет',
                                style: TextStyle(color: muted),
                              ),
                            ),
                          for (final e in history(book))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _GasMetalSurface(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label(e['key'] as String),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${show(e['old'])} → ${show(e['value'])}',
                                      style: const TextStyle(color: gold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_detailDate(DateTime.parse(e['at'] as String))} · ${_detailTime(DateTime.parse(e['at'] as String))}',
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ] else ...[
                          if (widget.group == 'Рабочий календарь')
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Праздники и переносы задаются по датам для каждого года. Новые годы автоматически не добавляются.',
                                style: TextStyle(color: muted, fontSize: 12),
                              ),
                            ),
                          for (final f in entries(widget.group!))
                            panel(
                              f.$2,
                              '${show(value(book, f.$1))}\n${f.$3}',
                              () => edit(book, f),
                              icon: Icons.edit_outlined,
                            ),
                        ],
                      ],
                    ),
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
