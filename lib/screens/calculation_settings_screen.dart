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
  static const gold = Color(0xFFE0AE63);
  static const white = Color(0xFFF1F1ED);
  static const muted = Color(0xFFAEB5B8);
  static const sectionBlue = Color(0xFF7F9AA8);

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
    if (value is num) {
      return value
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'\.?0+$'), '')
          .replaceAll('.', ',');
    }
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

  Future<void> _saveParameter(String key, Object selected) async {
    if (key.startsWith('salary.')) {
      if (selected is! num ||
          !selected.isFinite ||
          selected < 0 ||
          selected > 999999999)
        throw ArgumentError('Проверьте ставку');
      await TestStore.setSalaryRate(key.substring(7), selected.toDouble());
    } else {
      CalculationSettings.validate(key, selected);
      await TestStore.setCalculationSetting(key, selected);
    }
    if (mounted) setState(() {});
  }

  IconData groupIcon(String? name) => switch (name) {
    'Зарплата' => Icons.account_balance_wallet_outlined,
    'Рабочий календарь' => Icons.calendar_month_outlined,
    'Направления и суточные' => Icons.signpost_outlined,
    'Газ' => Icons.local_gas_station_outlined,
    'Обслуживание' => Icons.handyman_outlined,
    'История изменений' => Icons.history_rounded,
    _ => Icons.calculate_outlined,
  };

  String groupSubtitle(String group) => switch (group) {
    'Зарплата' => 'Оклад, доплаты и вес',
    'Рабочий календарь' => 'Рабочие дни, праздники и норма часов',
    'Направления и суточные' => 'Платные поездки и выплаты',
    'Газ' => 'Нормы расхода и газ в баке',
    _ => 'Интервалы обслуживания',
  };

  Widget _navigationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback action,
    bool hero = false,
  }) {
    return _SettingsInteractivePlate(
      onTap: busy ? null : action,
      hero: hero,
      child: Row(
        children: [
          _SettingsIconPlate(icon: icon, size: hero ? 52 : 42),
          SizedBox(width: hero ? 14 : 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: white,
                    fontSize: hero ? 18 : 15,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: hero ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: hero ? 11.5 : 10.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          _SettingsChevronButton(hero: hero),
        ],
      ),
    );
  }

  Widget _parameterTile(TestState book, (String, String, String) field) {
    final current = value(book, field.$1);
    if (current is bool)
      return SwitchListTile(
        title: Text(field.$2),
        value: current,
        onChanged: busy
            ? null
            : (v) async {
                try {
                  await _saveParameter(field.$1, v);
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('$e')));
                }
              },
      );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InlineValueInput(
        key: ValueKey(field.$1),
        label: field.$2,
        enabled: !busy,
        value: current is List ? current.join('\n') : show(current),
        multiline: current is List,
        save: (text) async {
          Object selected;
          if (current is List) {
            final list = text
                .split(RegExp(r'[,;\n]'))
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toSet()
                .toList();
            selected = field.$1 == 'workdays'
                ? list.map(int.parse).toList()
                : list;
          } else {
            final input = text.trim().replaceAll(' ', '').replaceAll(',', '.');
            if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(input))
              throw ArgumentError('Не более двух знаков после запятой');
            selected = double.parse(input);
          }
          await _saveParameter(field.$1, selected);
        },
      ),
    );
  }

  Widget _historyTile(Map<String, dynamic> event) {
    final at = DateTime.parse(event['at'] as String);
    final title = label(event['key'] as String);
    final oldText = show(event['old']);
    final newText = show(event['value']);

    return _SettingsInteractivePlate(
      onTap: () => showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: .72),
        builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF0C1216),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF8B6A3D), width: 1.1),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Было: $oldText\n\nСтало: $newText\n\n${_detailDate(at)} · ${_detailTime(at)}',
            style: const TextStyle(color: muted, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: gold),
              onPressed: () => Navigator.pop(c),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
      dense: true,
      child: Row(
        children: [
          const _SettingsIconPlate(icon: Icons.history_rounded, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$oldText  →  $newText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_detailDate(at)} · ${_detailTime(at)}',
                  style: const TextStyle(color: muted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: gold, size: 23),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 7, 2, 6),
    child: Row(
      children: [
        Container(
          width: 31,
          height: 25,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: const Color(0xC012181C),
            border: Border.all(color: const Color(0xFF6E5637), width: .7),
          ),
          child: Icon(icon, color: gold, size: 17),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: sectionBlue,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .25,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: _SettingsHairline()),
      ],
    ),
  );

  String get subtitle => widget.settingsRoot
      ? 'Управление приложением'
      : widget.group == null
      ? 'Ставки, нормы и правила учёта'
      : widget.group == 'История изменений'
      ? 'Сохранённые значения и даты'
      : switch (widget.group) {
          'Зарплата' => 'Ставки, доплаты и удержания',
          'Рабочий календарь' => 'Рабочие дни, праздники и норма часов',
          'Направления и суточные' => 'Платные поездки и выплаты',
          'Газ' => 'Нормы, остатки и учёт топлива',
          'Обслуживание' => 'Интервалы и регламент',
          _ => 'Нажмите параметр для изменения',
        };

  Widget header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsRoundButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Назад',
          onTap: busy ? null : () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.settingsRoot
                      ? 'Настройки'
                      : widget.group ?? 'Параметры расчётов',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.02,
                    shadows: [
                      Shadow(
                        color: Color(0x99000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 52,
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [gold, Color(0x00E0AE63)],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFC3C7C8),
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  void open(String? group, {bool root = false}) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      _SceneRoute<void>(
        builder: (_) =>
            _CalculationSettingsScreen(group: group, settingsRoot: root),
      ),
    );
  }

  List<Map<String, dynamic>> history(TestState b) {
    final result = [...b.calculationHistory];
    var previous = Map<String, double>.of(SalaryRates.defaults);
    for (final e in b.salaryRateHistory) {
      final rates = SalaryRates.decode(e['rates']);
      for (final key in rates.keys) {
        if (rates[key] != previous[key]) {
          result.add({
            'at': e['at'],
            'key': 'salary.$key',
            'old': previous[key],
            'value': rates[key],
          });
        }
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
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF080E12),
        body: Stack(
          children: [
            _CinematicMore.backdrop(),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0x16000000),
                        const Color(0x08000000),
                        const Color(0x50000000),
                      ],
                      stops: const [0, .48, 1],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  header(),
                  if (busy)
                    const LinearProgressIndicator(
                      color: gold,
                      backgroundColor: Color(0x331F2A30),
                      minHeight: 2,
                    ),
                  Expanded(
                    child: _TestLive(
                      builder: (book) {
                        final events = widget.group == 'История изменений'
                            ? history(book)
                            : <Map<String, dynamic>>[];

                        return ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                          children: [
                            if (widget.settingsRoot) ...[
                              _sectionHeader(
                                'Приложение',
                                Icons.settings_outlined,
                              ),
                              _navigationTile(
                                title: 'Параметры расчётов',
                                subtitle:
                                    'Ставки, календарь, газ и обслуживание',
                                icon: Icons.calculate_outlined,
                                action: () => open(null),
                                hero: true,
                              ),
                            ] else if (widget.group == null) ...[
                              _sectionHeader(
                                'Расчёты',
                                Icons.calculate_outlined,
                              ),
                              for (final g in groups)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: _navigationTile(
                                    title: g,
                                    subtitle: groupSubtitle(g),
                                    icon: groupIcon(g),
                                    action: () => open(g),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              _sectionHeader(
                                'Изменения',
                                Icons.history_rounded,
                              ),
                              _navigationTile(
                                title: 'История изменений',
                                subtitle: 'Значения и даты начала действия',
                                icon: Icons.history_rounded,
                                action: () => open('История изменений'),
                              ),
                            ] else if (widget.group == 'История изменений') ...[
                              _sectionHeader('История', Icons.history_rounded),
                              if (events.isEmpty)
                                const _SettingsEmptyPlate(
                                  icon: Icons.history_rounded,
                                  title: 'Изменений пока нет',
                                  subtitle:
                                      'Здесь появятся сохранённые настройки',
                                )
                              else
                                for (final e in events)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: _historyTile(e),
                                  ),
                            ] else ...[
                              _sectionHeader(
                                'Параметры',
                                groupIcon(widget.group),
                              ),
                              for (final f in entries(widget.group!))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: _parameterTile(book, f),
                                ),
                              if (widget.group == 'Рабочий календарь') ...[
                                const SizedBox(height: 5),
                                const _SettingsInfoPlate(
                                  text: 'Праздники и переносы задаются по датам для каждого года. Новые годы автоматически не добавляются.',
                                ),
                              ],
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

class _SettingsChrome {
  static BoxDecoration panelDecoration({
    double radius = 15,
    bool hero = false,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: hero ? const Color(0xFFA47743) : const Color(0xFF6F5739),
        width: hero ? 1.15 : .9,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: hero
            ? const [Color(0xF423292C), Color(0xF20D1418), Color(0xF5080D10)]
            : const [Color(0xF01A2023), Color(0xF20D1418), Color(0xF4070C0F)],
      ),
      boxShadow: [
        const BoxShadow(
          color: Color(0x88000000),
          blurRadius: 13,
          offset: Offset(0, 6),
        ),
        BoxShadow(
          color: const Color(0xFFE0AE63).withValues(alpha: hero ? .14 : .07),
          blurRadius: hero ? 9 : 4,
          spreadRadius: hero ? .2 : 0,
        ),
      ],
    );
  }
}

class _SettingsInteractivePlate extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool hero;
  final bool dense;

  const _SettingsInteractivePlate({
    required this.child,
    this.onTap,
    this.hero = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(hero ? 19 : 15);
    return Stack(
      children: [
        Container(
          constraints: BoxConstraints(
            minHeight: hero ? 104 : (dense ? 66 : 70),
          ),
          decoration: _SettingsChrome.panelDecoration(
            radius: hero ? 19 : 15,
            hero: hero,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              splashColor: const Color(0x22E0AE63),
              highlightColor: const Color(0x12E0AE63),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: hero ? 14 : 11,
                  vertical: hero ? 13 : (dense ? 8 : 9),
                ),
                child: child,
              ),
            ),
          ),
        ),
        const Positioned(left: 8, top: 8, child: _SettingsBolt()),
        const Positioned(right: 8, top: 8, child: _SettingsBolt()),
        const Positioned(left: 8, bottom: 8, child: _SettingsBolt()),
        const Positioned(right: 8, bottom: 8, child: _SettingsBolt()),
        Positioned(
          left: 25,
          right: 25,
          top: 0,
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [
                  Color(0x00E0AE63),
                  Color(0xA8E0AE63),
                  Color(0x00E0AE63),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsIconPlate extends StatelessWidget {
  final IconData icon;
  final double size;

  const _SettingsIconPlate({required this.icon, this.size = 52});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * .22),
      border: Border.all(color: const Color(0xFF8B6A3E), width: 1),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4C3824), Color(0xFF182126), Color(0xFF070C0F)],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0xAA000000),
          blurRadius: 6,
          offset: Offset(2, 4),
        ),
        BoxShadow(color: Color(0x22E0AE63), blurRadius: 4),
      ],
    ),
    child: Icon(
      icon,
      color: const Color(0xFFFFC977),
      size: size * .56,
      shadows: const [
        Shadow(color: Color(0xCC000000), blurRadius: 4, offset: Offset(1, 2)),
      ],
    ),
  );
}

class _SettingsChevronButton extends StatelessWidget {
  final bool hero;
  const _SettingsChevronButton({this.hero = false});

  @override
  Widget build(BuildContext context) => Container(
    width: hero ? 40 : 34,
    height: hero ? 40 : 34,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xA50A1014),
      border: Border.all(color: const Color(0xFF8B6A3E), width: .9),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 5,
          offset: Offset(1, 3),
        ),
      ],
    ),
    child: Icon(
      Icons.chevron_right_rounded,
      color: const Color(0xFFFFC977),
      size: hero ? 25 : 22,
    ),
  );
}

class _SettingsRoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _SettingsRoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xD20A1014),
      border: Border.all(color: const Color(0xFFB38348), width: 1.15),
      boxShadow: const [
        BoxShadow(
          color: Color(0x88000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
        BoxShadow(color: Color(0x26E0AE63), blurRadius: 4),
      ],
    ),
    child: IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      onPressed: onTap,
      icon: Icon(icon, color: const Color(0xFFFFC977), size: 28),
    ),
  );
}

class _SettingsBolt extends StatelessWidget {
  const _SettingsBolt();

  @override
  Widget build(BuildContext context) => Container(
    width: 4,
    height: 4,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF9D7B4C),
      border: Border.all(color: const Color(0xFF34291D), width: .5),
      boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 2)],
    ),
  );
}

class _SettingsHairline extends StatelessWidget {
  const _SettingsHairline();

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0x00708B96), Color(0x85708B96), Color(0x00708B96)],
      ),
    ),
  );
}

class _SettingsInfoPlate extends StatelessWidget {
  final String text;
  const _SettingsInfoPlate({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: _SettingsChrome.panelDecoration(radius: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: Color(0xFF7FA5B7),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF9FA8AC),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SettingsEmptyPlate extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsEmptyPlate({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => _SettingsInteractivePlate(
    child: Row(
      children: [
        _SettingsIconPlate(icon: icon, size: 42),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF1F1ED),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFFAEB5B8), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
