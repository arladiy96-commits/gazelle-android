part of 'app_shell.dart';

class _GasReportScreen extends StatefulWidget {
  final AppSession session;
  final ValueChanged<int> onNavigate;
  const _GasReportScreen({required this.session, required this.onNavigate});
  @override
  State<_GasReportScreen> createState() => _GasReportScreenState();
}

class _GasReportScreenState extends State<_GasReportScreen> {
  static const gold = _CinematicMore.gold;
  static const muted = Color(0xFF90999E);
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  GasReport? _report;
  String? _error, _keptSignature;
  bool _distance = false, _busy = false, _expanded = false;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    TestStore.revision.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    TestStore.revision.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final request = ++_request;
    try {
      final report = await GasReportRepository.load(_month);
      if (mounted && request == _request) {
        setState(() {
          _report = report;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && request == _request) {
        setState(() => _error = 'Не удалось загрузить отчёт: $e');
      }
    }
  }

  String _number(double v) {
    final value = v.abs() < 0.0000001 ? 0.0 : v;
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '')
        .replaceAll('.', ',')
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  }

  String _litres(double? v) => v == null ? '—' : '${_number(v)} л';
  String _monthName(DateTime d) => '${_garageMonths[d.month - 1]} ${d.year}';
  void _move(int delta) {
    if (_busy) {
      return;
    }
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _report = null;
      _error = null;
      _keptSignature = null;
    });
    _reload();
  }

  void _notice(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _commit(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      await _reload();
    } catch (e) {
      _notice(
        e.toString().replaceFirst(
          RegExp(r'^(Bad state: |Invalid argument\(s\): )'),
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _panel(
    Widget child, {
    EdgeInsets padding = const EdgeInsets.all(14),
  }) => _GasReportMoreSurface(padding: padding, child: child);
  Widget _action(
    String label,
    VoidCallback? onPressed, {
    IconData? icon,
  }) => TextButton(
    style: TextButton.styleFrom(
      foregroundColor: gold,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Flexible(child: Text(label)),
      ],
    ),
  );
  Future<void> _opening(GasReport report) async {
    final controller = TextEditingController(
      text: report.opening == null ? '' : _number(report.opening!),
    );
    String? error;
    final result = await showDialog<Object>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          backgroundColor: const Color(0xFF11181C),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: const BorderSide(color: Color(0xFF776044), width: .8),
          ),
          title: const Text(
            'Начальный остаток',
            style: TextStyle(color: Color(0xFFF1EEE6), fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Остаток газа с прошлого месяца',
                style: TextStyle(color: muted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Color(0xFFE9EAEB)),
                decoration: InputDecoration(
                  suffixText: 'л',
                  errorText: error,
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF5A656B)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: gold),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (report.manualOpening && report.carriedOpening != null)
                _action(
                  'Использовать перенос: ${_litres(report.carriedOpening)}',
                  () => Navigator.pop(dialog, 'carry'),
                ),
            ],
          ),
          actions: [
            _action('Отмена', () => Navigator.pop(dialog)),
            _action('Сохранить', () {
              final value = double.tryParse(
                controller.text.trim().replaceAll(' ', '').replaceAll(',', '.'),
              );
              if (value == null || !value.isFinite || value < 0) {
                update(() => error = 'Введите число не меньше нуля');
                return;
              }
              Navigator.pop(dialog, value);
            }),
          ],
        ),
      ),
    );
    // Let the dialog finish its closing transition before disposing its field.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (!mounted || result == null) {
      return;
    }
    await _commit(
      () => result == 'carry'
          ? GasReportRepository.useCarry(report.month)
          : GasReportRepository.setOpening(report.month, result as double),
    );
  }

  Future<void> _submit(GasReport report) async {
    final next = DateTime(report.month.year, report.month.month + 1);
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: const Color(0xFF11181C),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: Color(0xFF776044), width: .8),
        ),
        title: const Text(
          'Подтверждение',
          style: TextStyle(color: Color(0xFFE9EAEB), fontSize: 20),
        ),
        content: Text(
          '${report.submitted ? 'Обновить сданный отчёт' : 'Отметить отчёт'} за ${_monthName(report.month)}${report.submitted ? '?' : ' как сданный?'}\n\n'
          'Остаток ${_litres(report.closing)} будет перенесён в ${_monthName(next)} как начальный остаток. '
          'Если в следующем месяце указан ручной остаток, он сохранится до отмены ручной корректировки.',
          style: const TextStyle(
            color: Color(0xFFD5DADC),
            height: 1.4,
            fontSize: 15,
          ),
        ),
        actions: [
          _action('Отмена', () => Navigator.pop(dialog, false)),
          _action(
            report.submitted ? 'Обновить перенос' : 'Да, отчёт сдан',
            () => Navigator.pop(dialog, true),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await _commit(
        () => GasReportRepository.submit(
          report.month,
          expectedSignature: report.signature,
        ),
      );
    }
  }

  Widget _menuContent(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? action, {
    IconData arrow = Icons.chevron_right,
  }) => InkWell(
    onTap: action,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: FittedBox(
              child: _CinematicMore.badge(icon, action == null ? muted : gold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFE9EAEB),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            arrow,
            color: action == null ? muted : const Color(0xFFBDC3C5),
            size: 24,
          ),
        ],
      ),
    ),
  );

  Widget _summary(GasReport r) {
    Widget metric(
      String label,
      double? value,
      IconData icon, {
      bool negative = false,
    }) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: gold),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _litres(value),
                style: TextStyle(
                  color: negative
                      ? const Color(0xFFD29280)
                      : const Color(0xFFE9EAEB),
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      children: [
        _panel(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              metric('Получено', r.gas, Icons.propane_tank_outlined),
              metric(
                'Расход',
                r.consumption,
                Icons.local_fire_department_outlined,
              ),
              metric(
                'Остаток',
                r.closing,
                Icons.propane_tank_outlined,
                negative: (r.closing ?? 0) < 0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _GasReportMoreSurface(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: InkWell(
            onTap: _busy ? null : () => _opening(r),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const Text(
                    'На начало месяца: ',
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                  Expanded(
                    child: Text(
                      r.opening == null ? 'Указать' : _litres(r.opening),
                      style: const TextStyle(
                        color: gold,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.edit_outlined, color: gold, size: 19),
                ],
              ),
            ),
          ),
        ),
        if ((r.closing ?? 0) < 0)
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Text(
              'Отрицательный остаток: проверьте выдачи и начальный остаток.',
              style: TextStyle(color: Color(0xFFD29280), fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _status(GasReport r) {
    final kept = _keptSignature == r.signature;
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.changed) ...[
            const Text(
              'Данные сданного отчёта изменились',
              style: TextStyle(
                color: gold,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Сохранённый перенос: ${_litres(r.fixedClosing)}. Текущий расчёт: ${_litres(r.closing)}.',
              style: const TextStyle(color: muted, fontSize: 13),
            ),
            _action(
              'Пересчитать остаток и обновить перенос в следующий месяц',
              _busy || r.pending > 0 || r.opening == null
                  ? null
                  : () => _submit(r),
              icon: Icons.refresh,
            ),
            if (!kept)
              _action(
                'Оставить прежний перенос',
                () => setState(() => _keptSignature = r.signature),
              ),
            if (kept)
              const Text(
                'Прежний перенос сохранён.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
          ] else if (r.submitted) ...[
            Row(
              children: [
                const Icon(Icons.check, size: 18, color: Color(0xFF8AA394)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Отчёт сдан · ${_detailDate(r.submittedAt!)}',
                    style: const TextStyle(
                      color: Color(0xFFC9D5CC),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Зафиксированный остаток: ${_litres(r.fixedClosing)}',
              style: const TextStyle(color: muted, fontSize: 13),
            ),
          ] else
            _menuContent(
              'Отчёт сдан',
              'Перенести остаток в следующий месяц',
              Icons.check_circle_outline,
              _busy || r.pending > 0 || r.opening == null
                  ? null
                  : () => _submit(r),
            ),
          if (r.pending > 0)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                'Смен без окончательного пробега или незавершённых: ${r.pending}. Завершите их перед сдачей отчёта.',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ),
          if (r.opening == null)
            const Text(
              'Для сдачи укажите начальный остаток.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
        ],
      ),
    );
  }

  void _toggleTable() => setState(() => _expanded = !_expanded);
  Widget _table(GasReport r) {
    if (!_expanded)
      return _panel(
        _menuContent(
          'По дням',
          '${r.days.length} дн. · ${_number(r.km)} км',
          Icons.format_list_bulleted,
          _toggleTable,
          arrow: Icons.expand_more,
        ),
      );
    final rows = _expanded ? r.days : r.days.take(5).toList();
    final distance = _expanded && _distance;
    Widget cell(
      String value, {
      bool header = false,
      bool total = false,
      bool left = false,
    }) => Padding(
      padding: EdgeInsets.symmetric(horizontal: 3, vertical: header ? 8 : 6),
      child: Text(
        value,
        textAlign: left ? TextAlign.left : TextAlign.center,
        softWrap: true,
        style: TextStyle(
          color: header
              ? const Color(0xFF90999E)
              : total
              ? gold
              : const Color(0xFFE9EAEB),
          fontSize: header ? 9.5 : 10.5,
          height: 1.2,
          fontWeight: total ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
    TableRow line(
      List<String> values, {
      bool header = false,
      bool total = false,
      GasReportDay? day,
    }) => TableRow(
      decoration: BoxDecoration(
        color: header
            ? const Color(0x70111B20)
            : total
            ? const Color(0x9910191C)
            : Colors.transparent,
      ),
      children: [
        for (var i = 0; i < values.length; i++)
          if (day != null)
            InkWell(
              onTap: () => _openDaySummary(context, day.date),
              child: cell(values[i], left: i == values.length - 1),
            )
          else
            cell(
              values[i],
              header: header,
              total: total,
              left: i == values.length - 1,
            ),
      ],
    );
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _expanded ? 'Журнал за месяц' : 'По дням',
                    style: const TextStyle(
                      color: Color(0xFFE9EAEB),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: _toggleTable,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: gold,
                    side: const BorderSide(color: Color(0xFF997B48), width: .8),
                    backgroundColor: const Color(0x303F301B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(
                    _expanded ? 'Свернуть ↙' : 'Развернуть ↗',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 8),
              child: Row(
                children: [
                  for (final mode in [false, true])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: TextButton(
                          onPressed: () => setState(() => _distance = mode),
                          style: TextButton.styleFrom(
                            foregroundColor: _distance == mode ? gold : muted,
                            backgroundColor: _distance == mode
                                ? const Color(0x664B391E)
                                : const Color(0x99081015),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                              side: BorderSide(
                                color: _distance == mode
                                    ? const Color(0xFFA78951)
                                    : const Color(0xFF39464C),
                                width: .8,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            mode ? 'Пробег за день' : 'Показания одометра',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(
                color: const Color(0xFF353A3D),
                width: .5,
                borderRadius: BorderRadius.circular(7),
              ),
              columnWidths: distance
                  ? const {
                      0: FlexColumnWidth(12),
                      1: FlexColumnWidth(21),
                      2: FlexColumnWidth(12),
                      3: FlexColumnWidth(13),
                      4: FlexColumnWidth(42),
                    }
                  : const {
                      0: FlexColumnWidth(11),
                      1: FlexColumnWidth(17),
                      2: FlexColumnWidth(17),
                      3: FlexColumnWidth(10),
                      4: FlexColumnWidth(11),
                      5: FlexColumnWidth(34),
                    },
              children: [
                line([
                  'Дата',
                  if (distance)
                    'Пробег\nза день, км'
                  else ...[
                    'Начало,\nкм',
                    'Конец,\nкм',
                  ],
                  'Газ,\nл',
                  'Бензин,\nл',
                  'Направление',
                ], header: true),
                for (final d in rows)
                  line([
                    '${d.date.day.toString().padLeft(2, '0')}.${d.date.month.toString().padLeft(2, '0')}',
                    if (distance)
                      '${_number(d.km)}${d.pending > 0 ? ' *' : ''}'
                    else ...[
                      d.startKm == null ? '—' : _number(d.startKm!),
                      d.endKm == null ? '—' : _number(d.endKm!),
                    ],
                    d.gas == 0 ? '—' : _number(d.gas),
                    d.petrol == 0 ? '—' : _number(d.petrol),
                    d.directions.isEmpty ? '—' : d.directions,
                  ], day: d),
                if (_expanded)
                  line([
                    'Итого',
                    _number(r.km),
                    if (!distance) 'км',
                    _number(r.gas),
                    _number(r.petrol),
                    '',
                  ], total: true),
              ],
            ),
          ),
          if (r.days.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'В этом месяце смен пока нет.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
          if (!_expanded && r.days.isNotEmpty)
            TextButton(
              onPressed: _toggleTable,
              style: TextButton.styleFrom(foregroundColor: muted),
              child: Text(
                'Показано ${rows.length} из ${r.days.length} дней ⌄',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          if (_expanded)
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Нажмите строку, чтобы открыть сводку дня',
                style: TextStyle(color: muted, fontSize: 10),
              ),
            ),
          if (r.pending > 0)
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                '* Учтён только сохранённый пробег; итог незавершённых смен может измениться.',
                style: TextStyle(color: muted, fontSize: 10),
              ),
            ),
        ],
      ),
      padding: EdgeInsets.zero,
    );
  }

  Widget _referenceReport(GasReport r, bool canNext) {
    const ivory = Color(0xFFF1EEE6);
    const amber = Color(0xFFE7B76A);
    Widget label(
      String text,
      double size, {
      Color color = ivory,
      FontWeight weight = FontWeight.w400,
      TextAlign align = TextAlign.left,
    }) => Text(
      text,
      textAlign: align,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        height: 1.15,
      ),
    );
    Widget fitted(String text, double size, {Color color = ivory}) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: label(text, size, color: color, weight: FontWeight.w600),
    );
    Widget badge(IconData icon, {double size = 54}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3E3728), Color(0xFF101719), Color(0xFF090E10)],
        ),
        border: Border.all(color: const Color(0xFF8D7550), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 5,
            offset: Offset(2, 3),
          ),
        ],
      ),
      child: Icon(icon, color: amber, size: size * .56),
    );
    Widget surface(Widget child, {bool highlight = false}) => Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: highlight
              ? const [Color(0xD9463016), Color(0xEF101516)]
              : const [Color(0xDC151C1F), Color(0xED080E10)],
        ),
        border: Border.all(
          color: highlight ? amber : const Color(0xFF51514A),
          width: 1.2,
        ),
        boxShadow: highlight
            ? const [BoxShadow(color: Color(0x557E4D15), blurRadius: 8)]
            : null,
      ),
      child: child,
    );
    Widget metric(
      String title,
      String value,
      IconData icon, {
      String? subtitle,
    }) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF424644), width: 1),
          ),
        ),
        child: Row(
          children: [
            badge(icon),
            const SizedBox(width: 25),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label(title, 22, color: const Color(0xFFB6BFC1)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 5),
                    label(subtitle, 18, color: muted),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 142, child: fitted(value, 29, color: amber)),
          ],
        ),
      ),
    );
    Widget journalLine(
      List<String> cells, {
      bool header = false,
      bool total = false,
      GasReportDay? day,
    }) {
      final weights = _distance
          ? [12, 29, 13, 14, 32]
          : [12, 16, 15, 13, 14, 30];
      final row = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: weights[i],
              child: Container(
                alignment: i == cells.length - 1
                    ? Alignment.centerLeft
                    : Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: const Color(0xFF353C3E),
                      width: i == cells.length - 1 ? 0 : 1,
                    ),
                    bottom: const BorderSide(
                      color: Color(0xFF353C3E),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  cells[i],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: i == cells.length - 1
                      ? TextAlign.left
                      : TextAlign.center,
                  style: TextStyle(
                    color: total ? amber : const Color(0xFFBBC4C7),
                    fontSize: header ? 16 : 18,
                    fontWeight: total ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
        ],
      );
      return SizedBox(
        height: 49,
        child: day == null
            ? row
            : InkWell(
                onTap: () => _openDaySummary(context, day.date),
                child: row,
              ),
      );
    }

    void form() => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _GasFormPreview(
          report: r,
          name: widget.session.displayName,
          distance: _distance,
        ),
      ),
    );
    void expandJournal() {
      showDialog<void>(
        context: context,
        barrierColor: const Color(0xAA000000),
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, refresh) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 16,
              ),
              child: LayoutBuilder(
                builder: (context, box) {
                  final scale = box.maxWidth / 800;
                  final height = box.maxHeight / scale;
                  return SizedBox(
                    width: box.maxWidth,
                    height: box.maxHeight,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: SizedBox(
                        width: 800,
                        height: height,
                        child: surface(
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: label(
                                        'Журнал за месяц',
                                        34,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      child: label(
                                        'Свернуть ↙',
                                        25,
                                        color: amber,
                                      ),
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: label(
                                    _monthName(_month),
                                    23,
                                    color: muted,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 76,
                                  child: Row(
                                    children: [
                                      for (final distance in [false, true])
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              setState(
                                                () => _distance = distance,
                                              );
                                              refresh(() {});
                                            },
                                            child: surface(
                                              Center(
                                                child: label(
                                                  distance
                                                      ? 'Пробег за день'
                                                      : 'Показания одометра',
                                                  23,
                                                  color: _distance == distance
                                                      ? amber
                                                      : muted,
                                                ),
                                              ),
                                              highlight: _distance == distance,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                journalLine([
                                  'Дата',
                                  if (_distance)
                                    'Пробег, км'
                                  else ...[
                                    'Начало, км',
                                    'Конец, км',
                                  ],
                                  'Газ, л',
                                  'Бензин, л',
                                  'Направление',
                                ], header: true),
                                Expanded(
                                  child: r.days.isEmpty
                                      ? Center(
                                          child: label(
                                            'В этом месяце смен пока нет',
                                            24,
                                            color: muted,
                                          ),
                                        )
                                      : ListView(
                                          padding: EdgeInsets.zero,
                                          children: [
                                            for (final d in r.days)
                                              journalLine([
                                                '${d.date.day.toString().padLeft(2, '0')}.${d.date.month.toString().padLeft(2, '0')}',
                                                if (_distance)
                                                  '${_number(d.km)}${d.pending > 0 ? ' *' : ''}'
                                                else ...[
                                                  d.startKm == null
                                                      ? '—'
                                                      : _number(d.startKm!),
                                                  d.endKm == null
                                                      ? '—'
                                                      : _number(d.endKm!),
                                                ],
                                                d.gas == 0
                                                    ? '—'
                                                    : _number(d.gas),
                                                d.petrol == 0
                                                    ? '—'
                                                    : _number(d.petrol),
                                                d.directions.isEmpty
                                                    ? '—'
                                                    : d.directions,
                                              ], day: d),
                                          ],
                                        ),
                                ),
                                journalLine([
                                  'Итого',
                                  '${_number(r.km)}${_distance ? ' км' : ''}',
                                  if (!_distance) 'км',
                                  _litres(r.gas),
                                  _litres(r.petrol),
                                  '—',
                                ], total: true),
                                const SizedBox(height: 16),
                                label(
                                  '${r.days.length} дн. · ${_number(r.km)} км',
                                  23,
                                  color: muted,
                                ),
                                const SizedBox(height: 10),
                                label(
                                  'Нажмите строку, чтобы открыть сводку дня',
                                  20,
                                  color: muted,
                                ),
                              ],
                            ),
                          ),
                          highlight: true,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    void changedReport() {
      showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          backgroundColor: const Color(0xFF11181C),
          title: const Text('Данные сданного отчёта изменились'),
          content: Text(
            'Сохранённый перенос: ${_litres(r.fixedClosing)}. Текущий расчёт: ${_litres(r.closing)}.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialog);
                setState(() => _keptSignature = r.signature);
              },
              child: const Text('Оставить прежний перенос'),
            ),
            TextButton(
              onPressed: _busy || r.pending > 0 || r.opening == null
                  ? null
                  : () {
                      Navigator.pop(dialog);
                      _submit(r);
                    },
              child: const Text('Обновить перенос'),
            ),
          ],
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
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
            Positioned.fill(
              child: Image.asset(
                'assets/images/scenes/gas_report_reference.png',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = constraints.maxWidth / 864;
                  final height = math.max(
                    1536.0,
                    constraints.maxHeight / scale,
                  );
                  final ratio = height / 1536;
                  Widget at(
                    double x,
                    double y,
                    double w,
                    double h,
                    Widget child,
                  ) => Positioned(
                    left: x,
                    top: y * ratio,
                    width: w,
                    height: h * ratio,
                    child: child,
                  );
                  return SingleChildScrollView(
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: height * scale,
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: SizedBox(
                          width: 864,
                          height: height,
                          child: Material(
                            color: Colors.transparent,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.asset(
                                    'assets/images/scenes/gas_report_reference.png',
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                at(
                                  30,
                                  20,
                                  90,
                                  90,
                                  IconButton(
                                    tooltip: 'Назад',
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      color: amber,
                                      size: 49,
                                    ),
                                  ),
                                ),
                                at(
                                  140,
                                  30,
                                  680,
                                  76,
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: label(
                                      'Отчёт за газ',
                                      57,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                at(
                                  100,
                                  121,
                                  449,
                                  72,
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 75,
                                        child: IconButton(
                                          tooltip: 'Предыдущий месяц',
                                          onPressed: _busy
                                              ? null
                                              : () => _move(-1),
                                          icon: const Icon(
                                            Icons.chevron_left,
                                            color: amber,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: label(
                                            _monthName(_month),
                                            28,
                                            color: amber,
                                            weight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 75,
                                        child: IconButton(
                                          tooltip: 'Следующий месяц',
                                          onPressed: canNext && !_busy
                                              ? () => _move(1)
                                              : null,
                                          icon: Icon(
                                            Icons.chevron_right,
                                            color: canNext && !_busy
                                                ? amber
                                                : muted,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                at(
                                  96,
                                  247,
                                  480,
                                  48,
                                  label(
                                    'Итоги месяца',
                                    36,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                at(
                                  82,
                                  304,
                                  516,
                                  280,
                                  surface(
                                    Column(
                                      children: [
                                        metric(
                                          'Остаток\nс прошлого месяца',
                                          _litres(r.opening),
                                          Icons.inventory_2_outlined,
                                        ),
                                        metric(
                                          'Получено газа\nза месяц',
                                          _litres(r.gas),
                                          Icons.local_shipping_outlined,
                                        ),
                                        metric(
                                          'Пробег за месяц',
                                          '${_number(r.km)} км',
                                          Icons.add_road,
                                        ),
                                        metric(
                                          'Расход по норме',
                                          _litres(r.consumption),
                                          Icons.bar_chart,
                                          subtitle:
                                              'Норма ${r.normDescription}',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                at(
                                  82,
                                  597,
                                  516,
                                  83,
                                  surface(
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Row(
                                        children: [
                                          badge(
                                            Icons.local_gas_station_outlined,
                                          ),
                                          const SizedBox(width: 25),
                                          Expanded(
                                            child: label(
                                              'Текущий остаток',
                                              23,
                                              color: amber,
                                              weight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            width: 195,
                                            child: fitted(
                                              _litres(r.closing),
                                              51,
                                              color: (r.closing ?? 0) < 0
                                                  ? const Color(0xFFD29280)
                                                  : const Color(0xFFFFE5AE),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    highlight: true,
                                  ),
                                ),
                                at(
                                  82,
                                  693,
                                  516,
                                  62,
                                  surface(
                                    InkWell(
                                      onTap: _busy ? null : () => _opening(r),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                        ),
                                        child: Row(
                                          children: [
                                            badge(Icons.settings, size: 42),
                                            const SizedBox(width: 22),
                                            Expanded(
                                              child: label(
                                                'На начало месяца:  ${_litres(r.opening)}',
                                                21,
                                                color: const Color(0xFFB6BFC1),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.edit_outlined,
                                              color: amber,
                                              size: 31,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                at(
                                  82,
                                  851,
                                  500,
                                  52,
                                  label(
                                    'Журнал за месяц',
                                    35,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                at(
                                  603,
                                  846,
                                  204,
                                  60,
                                  surface(
                                    InkWell(
                                      onTap: expandJournal,
                                      child: Center(
                                        child: label(
                                          'Развернуть ↗',
                                          24,
                                          color: amber,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    highlight: true,
                                  ),
                                ),
                                at(
                                  61,
                                  919,
                                  744,
                                  62,
                                  Row(
                                    children: [
                                      for (final distance in [false, true])
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => setState(
                                              () => _distance = distance,
                                            ),
                                            child: surface(
                                              Center(
                                                child: label(
                                                  distance
                                                      ? 'Пробег за день'
                                                      : 'Показания одометра',
                                                  22,
                                                  color: _distance == distance
                                                      ? amber
                                                      : const Color(0xFFB6BFC1),
                                                  weight: _distance == distance
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                ),
                                              ),
                                              highlight: _distance == distance,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                at(
                                  58,
                                  993,
                                  750,
                                  193,
                                  surface(
                                    Column(
                                      children: [
                                        journalLine([
                                          'Дата',
                                          if (_distance)
                                            'Пробег, км'
                                          else ...[
                                            'Начало, км',
                                            'Конец, км',
                                          ],
                                          'Газ, л',
                                          'Бензин, л',
                                          'Направление',
                                        ], header: true),
                                        Expanded(
                                          child: r.days.isEmpty
                                              ? Center(
                                                  child: label(
                                                    'В этом месяце смен пока нет',
                                                    22,
                                                    color: muted,
                                                  ),
                                                )
                                              : ListView(
                                                  padding: EdgeInsets.zero,
                                                  children: [
                                                    for (final d in r.days)
                                                      journalLine([
                                                        '${d.date.day.toString().padLeft(2, '0')}.${d.date.month.toString().padLeft(2, '0')}',
                                                        if (_distance)
                                                          '${_number(d.km)}${d.pending > 0 ? ' *' : ''}'
                                                        else ...[
                                                          d.startKm == null
                                                              ? '—'
                                                              : _number(
                                                                  d.startKm!,
                                                                ),
                                                          d.endKm == null
                                                              ? '—'
                                                              : _number(
                                                                  d.endKm!,
                                                                ),
                                                        ],
                                                        d.gas == 0
                                                            ? '—'
                                                            : _number(d.gas),
                                                        d.petrol == 0
                                                            ? '—'
                                                            : _number(d.petrol),
                                                        d.directions.isEmpty
                                                            ? '—'
                                                            : d.directions,
                                                      ], day: d),
                                                  ],
                                                ),
                                        ),
                                        journalLine([
                                          'Итого',
                                          '${_number(r.km)}${_distance ? ' км' : ''}',
                                          if (!_distance) 'км',
                                          _litres(r.gas),
                                          _litres(r.petrol),
                                          '—',
                                        ], total: true),
                                      ],
                                    ),
                                  ),
                                ),
                                at(
                                  76,
                                  1190,
                                  725,
                                  42,
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_month,
                                        color: amber,
                                        size: 25,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: label(
                                          '${r.days.length} дн. · ${_number(r.km)} км${r.pending > 0 ? ' · Незавершённых: ${r.pending}' : ''}',
                                          20,
                                          color: const Color(0xFFB6BFC1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                at(
                                  65,
                                  1280,
                                  740,
                                  92,
                                  InkWell(
                                    onTap: _busy ? null : form,
                                    child: Row(
                                      children: [
                                        badge(
                                          Icons.description_outlined,
                                          size: 80,
                                        ),
                                        const SizedBox(width: 32),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              label(
                                                'Открыть бланк',
                                                30,
                                                weight: FontWeight.w600,
                                              ),
                                              const SizedBox(height: 5),
                                              label(
                                                'Просмотр и сохранение картинки',
                                                21,
                                                color: muted,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          size: 40,
                                          color: amber,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                at(
                                  65,
                                  1396,
                                  740,
                                  97,
                                  InkWell(
                                    onTap:
                                        _busy ||
                                            r.submitted ||
                                            r.pending > 0 ||
                                            r.opening == null
                                        ? null
                                        : () => _submit(r),
                                    child: Row(
                                      children: [
                                        badge(
                                          r.changed
                                              ? Icons.refresh
                                              : Icons.check_circle_outline,
                                          size: 80,
                                        ),
                                        const SizedBox(width: 32),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              label(
                                                _busy
                                                    ? 'Сохранение…'
                                                    : r.submitted
                                                    ? 'Отчёт сдан'
                                                    : 'Сдать отчёт',
                                                30,
                                                weight: FontWeight.w600,
                                              ),
                                              const SizedBox(height: 5),
                                              label(
                                                r.changed
                                                    ? 'Данные изменились · проверить перенос'
                                                    : r.submitted
                                                    ? 'Зафиксировано: ${_litres(r.fixedClosing)}'
                                                    : r.opening == null
                                                    ? 'Укажите начальный остаток'
                                                    : r.pending > 0
                                                    ? 'Сначала завершите смены: ${r.pending}'
                                                    : 'Перенести остаток в следующий месяц',
                                                21,
                                                color: muted,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (r.changed &&
                                            _keptSignature != r.signature)
                                          IconButton(
                                            tooltip: 'Проверить изменившийся перенос',
                                            onPressed: _busy
                                                ? null
                                                : changedReport,
                                            icon: const Icon(
                                              Icons.info_outline,
                                              size: 40,
                                              color: amber,
                                            ),
                                          )
                                        else if (!r.submitted)
                                          const Icon(
                                            Icons.chevron_right,
                                            size: 40,
                                            color: amber,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now(), r = _report;
    final canNext = _month.isBefore(DateTime(now.year, now.month));
    if (r != null && _error == null) return _referenceReport(r, canNext);
    return AnnotatedRegion<SystemUiOverlayStyle>(
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
            Positioned.fill(
              child: Image.asset(
                'assets/images/scenes/gas_report_reference.png',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.chevron_left, color: gold),
                      ),
                      const Expanded(
                        child: Text(
                          'Отчёт за газ',
                          style: TextStyle(
                            fontSize: 25,
                            color: Color(0xFFF1EEE6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: _error == null
                          ? const CircularProgressIndicator(color: gold)
                          : _panel(
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _error!,
                                    style: const TextStyle(color: muted),
                                  ),
                                  _action('Повторить', _reload),
                                ],
                              ),
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
}

// Reuse More styling without changing report dimensions or shared gas surfaces.
class _GasReportMoreSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _GasReportMoreSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: _CinematicMore.panel(),
    child: Padding(padding: padding, child: child),
  );
}

// Reuse the approved Work artwork directly. Nine-slice drawing preserves the
// metal corners and rim thickness while the report keeps its adaptive layout.
class _GasMetalSurface extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool compact;
  const _GasMetalSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.compact = false,
  });

  @override
  State<_GasMetalSurface> createState() => _GasMetalSurfaceState();
}

class _GasMetalSurfaceState extends State<_GasMetalSurface> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _artwork;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = const AssetImage('assets/images/scenes/work_shift_scene.png')
        .resolve(createLocalImageConfiguration(context));
    if (_stream?.key == stream.key) return;
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = stream;
    _listener = ImageStreamListener((info, synchronousCall) {
      final previous = _artwork;
      setState(() => _artwork = info);
      previous?.dispose();
    });
    stream.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _artwork?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _GasMetalPainter(_artwork, compact: widget.compact),
    child: Padding(padding: widget.padding, child: widget.child),
  );
}

class _GasMetalPainter extends CustomPainter {
  final ImageInfo? artwork;
  final bool compact;
  const _GasMetalPainter(this.artwork, {required this.compact});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final image = artwork?.image;
    if (image == null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
        Paint()..color = const Color(0xFF141719),
      );
      return;
    }
    // Source bounds include the complete rim, without neighbouring panels.
    final source = compact
        ? const Rect.fromLTRB(18, 632, 302, 844)
        : const Rect.fromLTRB(17, 1057, 837, 1567);
    final sx = image.width / 852;
    final sy = image.height / 1846;
    const corner = 34.0;
    final edge = math.min(14.0, math.min(size.width, size.height) / 2);
    final xs = [
      source.left,
      source.left + corner,
      source.right - corner,
      source.right,
    ];
    final ys = [
      source.top,
      source.top + corner,
      source.bottom - corner,
      source.bottom,
    ];
    final dx = [0.0, edge, size.width - edge, size.width];
    final dy = [0.0, edge, size.height - edge, size.height];
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      // Neutral graphite surfaces and warm metal, matching the Home panels.
      // Mix the blue reflections toward grey without tinting text or status colours.
      ..colorFilter = const ColorFilter.matrix(<double>[
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
      ]);
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 3; column++) {
        canvas.drawImageRect(
          image,
          Rect.fromLTRB(
            xs[column] * sx,
            ys[row] * sy,
            xs[column + 1] * sx,
            ys[row + 1] * sy,
          ),
          Rect.fromLTRB(dx[column], dy[row], dx[column + 1], dy[row + 1]),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GasMetalPainter oldDelegate) =>
      oldDelegate.artwork != artwork || oldDelegate.compact != compact;
}

class _GasFormPreview extends StatefulWidget {
  final GasReport report;
  final String name;
  final bool distance;
  const _GasFormPreview({
    required this.report,
    required this.name,
    this.distance = false,
  });
  @override
  State<_GasFormPreview> createState() => _GasFormPreviewState();
}

class _GasFormPreviewState extends State<_GasFormPreview> {
  static const _channel = MethodChannel('melnitsa/advance_image');
  late bool _distanceMode = widget.distance;
  final _organization = TextEditingController();
  final _vehicle = TextEditingController();
  late final _name = TextEditingController(text: widget.name);
  dynamic _bytes;
  bool _busy = false;
  String? _error;
  String _num(double? n) => n == null
      ? '—'
      : n
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'\.?0+$'), '')
            .replaceAll('.', ',');
  @override
  void dispose() {
    _organization.dispose();
    _vehicle.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _render() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = widget.report;
      final book = await TestStore.load();
      final hours = <String, double>{};
      final missingHours = <String>{};
      for (final shift in book.shifts.where(
        (s) => book.inMonth(s['start'] as String, r.month),
      )) {
        final key = TestState.dayKey(DateTime.parse(shift['start'] as String));
        if (shift['hoursWorked'] is num) {
          hours[key] = (hours[key] ?? 0) + book.hours(shift);
        } else {
          missingHours.add(key);
        }
      }
      final data = await _channel.invokeMethod<dynamic>('renderGas', {
        'organization': _organization.text.trim(),
        'vehicle': _vehicle.text.trim(),
        'name': _name.text.trim(),
        'norm': r.normDescription,
        'distanceMode': _distanceMode,
        'km': _num(r.km),
        'month': '${_garageMonths[r.month.month - 1]} ${r.month.year}',
        'opening': _num(r.opening),
        'closing': _num(r.closing),
        'gas': _num(r.gas),
        'rows': [
          for (final d in r.days)
            [
              '${d.date.day.toString().padLeft(2, '0')}.${d.date.month.toString().padLeft(2, '0')}',
              missingHours.contains(TestState.dayKey(d.date))
                  ? '—'
                  : _num(hours[TestState.dayKey(d.date)]),
              if (_distanceMode)
                _num(d.km)
              else ...[
                _num(d.startKm),
                _num(d.endKm),
              ],
              _num(d.gas),
              [
                d.directions,
                if (!_distanceMode && (d.startKm == null || d.endKm == null))
                  'Пробег: ${_num(d.km)} км',
              ].where((s) => s.isNotEmpty).join('; '),
            ],
        ],
        'note': [
          if (r.opening == null) 'Начальный остаток не задан.',
          if (r.pending > 0) 'Есть незавершённые смены или неуказанный пробег.',
          if (missingHours.isNotEmpty) 'Неуказанные часы отмечены прочерком.',
          if (r.changed)
            'Данные сданного отчёта изменились. Показан текущий расчёт.',
        ].join(' '),
      });
      if (mounted) setState(() => _bytes = data);
    } catch (e) {
      if (mounted) setState(() => _error = 'Не удалось создать бланк: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final saved = await _channel.invokeMethod<bool>('save', {
        'bytes': _bytes,
        'kind': 'gas',
      });
      if (mounted && saved == true)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Картинка сохранена')));
    } catch (e) {
      if (mounted) setState(() => _error = 'Не удалось сохранить: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      backgroundColor: const Color(0xFF111619),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111619),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !_busy,
        title: const Text('Карточка водителя'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            Expanded(
              child: _bytes == null
                  ? ListView(
                      padding: const EdgeInsets.all(18),
                      children: [
                        _GasMetalSurface(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Пробег в бланке',
                                style: TextStyle(color: Colors.white),
                              ),
                              RadioListTile<bool>(
                                value: false,
                                groupValue: _distanceMode,
                                activeColor: _CinematicMore.gold,
                                title: const Text(
                                  'Показания одометра',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onChanged: _busy
                                    ? null
                                    : (value) => setState(
                                        () => _distanceMode = value!,
                                      ),
                              ),
                              RadioListTile<bool>(
                                value: true,
                                groupValue: _distanceMode,
                                activeColor: _CinematicMore.gold,
                                title: const Text(
                                  'Пробег за день',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onChanged: _busy
                                    ? null
                                    : (value) => setState(
                                        () => _distanceMode = value!,
                                      ),
                              ),
                              for (final field in [
                                (
                                  _organization,
                                  'Организация (можно оставить пустым)',
                                ),
                                (_vehicle, 'Марка техники'),
                                (_name, 'ФИО водителя'),
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: TextField(
                                    controller: field.$1,
                                    enabled: !_busy,
                                    maxLength: 120,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: field.$2,
                                      counterText: '',
                                      labelStyle: const TextStyle(
                                        color: Color(0xFFB1B4B4),
                                      ),
                                    ),
                                  ),
                                ),
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () {
                                        FocusScope.of(context).unfocus();
                                        _render();
                                      },
                                child: const Text('Сформировать бланк'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : InteractiveViewer(
                      minScale: 1,
                      maxScale: 6,
                      child: Center(
                        child: Image.memory(_bytes, fit: BoxFit.contain),
                      ),
                    ),
            ),
            if (_busy) const LinearProgressIndicator(),
            if (_bytes != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _bytes = null;
                            _error = null;
                          }),
                    child: const Text('Реквизиты'),
                  ),
                  TextButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Сохранить картинку'),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}
