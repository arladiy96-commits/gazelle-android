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
  static const muted = Color(0xFFA9B2B6);
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  GasReport? _report;
  String? _error, _keptSignature;
  bool _distance = false, _busy = false;
  int _request = 0;
  final _horizontal = ScrollController();
  @override
  void initState() {
    super.initState();
    TestStore.revision.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    TestStore.revision.removeListener(_reload);
    _horizontal.dispose();
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
        .replaceAll('.', ',');
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
  }) => Container(
    decoration: _CinematicMore.panel(),
    padding: padding,
    child: child,
  );
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
          backgroundColor: const Color(0xFF10191E),
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
                style: const TextStyle(color: Colors.white),
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
        backgroundColor: const Color(0xFF10191E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: Color(0xFF776044), width: .8),
        ),
        title: const Text(
          'Подтверждение',
          style: TextStyle(color: Colors.white, fontSize: 20),
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

  Widget _stat(String label, String value, {String? note}) => Padding(
    padding: const EdgeInsets.only(bottom: 12, right: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFF0F1EF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              note,
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ),
      ],
    ),
  );
  Widget _summary(GasReport r) => _panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Итоги месяца',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _stat('Остаток с прошлого месяца', _litres(r.opening)),
            ),
            Expanded(child: _stat('Получено газа', _litres(r.gas))),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _stat('Пробег за месяц', '${_number(r.km)} км')),
            Expanded(
              child: _stat(
                'Расход по норме',
                _litres(r.consumption),
                note: 'Норма 28 л / 100 км',
              ),
            ),
          ],
        ),
        const Divider(height: 12, color: Color(0xFF44413A)),
        const SizedBox(height: 6),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Текущий остаток',
                style: TextStyle(color: Color(0xFFE8E8E4), fontSize: 15),
              ),
            ),
            Text(
              _litres(r.closing),
              style: TextStyle(
                color: (r.closing ?? 0) < 0 ? const Color(0xFFD29280) : gold,
                fontSize: 25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if ((r.closing ?? 0) < 0)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Отрицательный остаток: проверьте выдачи газа и начальный остаток.',
              style: TextStyle(color: Color(0xFFD29280), fontSize: 12),
            ),
          ),
        _action(
          r.opening == null
              ? 'Указать остаток с прошлого месяца'
              : '${r.manualOpening ? 'Начальный остаток указан вручную' : 'Перенесено из сданного отчёта'} · Изменить',
          _busy ? null : () => _opening(r),
          icon: Icons.edit_outlined,
        ),
      ],
    ),
  );
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
            _action(
              'Отчёт сдан',
              _busy || r.pending > 0 || r.opening == null
                  ? null
                  : () => _submit(r),
              icon: Icons.check_circle_outline,
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

  Widget _cell(
    String text,
    double width, {
    bool header = false,
    bool total = false,
    bool left = false,
    double? height,
  }) => Container(
    width: width,
    height: height ?? (header ? 64 : 56),
    alignment: left ? Alignment.centerLeft : Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFF303D43), width: .6)),
    ),
    child: Text(
      text,
      maxLines: header ? 3 : 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: header
            ? muted
            : total
            ? gold
            : const Color(0xFFE7EBEC),
        fontSize: header ? 12 : 14,
        fontWeight: total ? FontWeight.w600 : FontWeight.w400,
      ),
    ),
  );
  Widget _table(GasReport r) {
    final directionWidth = math.max(
      250.0,
      r.days.fold<double>(0, (value, d) {
        final painter = TextPainter(
          text: TextSpan(
            text: d.directions,
            style: const TextStyle(fontSize: 14),
          ),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final width = painter.width + 24;
        painter.dispose();
        return math.max(value, width);
      }),
    );
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text(
              'По дням',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (final distance in [false, true])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: TextButton(
                        onPressed: () => setState(() => _distance = distance),
                        style: TextButton.styleFrom(
                          foregroundColor: _distance == distance ? gold : muted,
                          backgroundColor: _distance == distance
                              ? const Color(0x443F301E)
                              : Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _distance == distance
                                  ? const Color(0xFF977441)
                                  : const Color(0xFF475056),
                              width: .8,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          distance ? 'Пробег за день' : 'Показания одометра',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              'Листайте колонки ↔ · Нажмите дату для сводки дня',
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF111C22),
                  border: Border(
                    right: BorderSide(color: Color(0xFF776044), width: .8),
                  ),
                ),
                child: Column(
                  children: [
                    _cell('Дата', 62, header: true, left: true),
                    for (final d in r.days)
                      InkWell(
                        onTap: () => _openDaySummary(context, d.date),
                        child: _cell(
                          '${d.date.day.toString().padLeft(2, '0')}.${d.date.month.toString().padLeft(2, '0')}',
                          62,
                          left: true,
                        ),
                      ),
                    _cell('Итого', 62, total: true, left: true),
                  ],
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: _horizontal,
                  thumbVisibility: true,
                  notificationPredicate: (n) =>
                      n.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: _horizontal,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_distance)
                              _cell('Пробег за день, км', 114, header: true)
                            else ...[
                              _cell('Пробег на начало, км', 114, header: true),
                              _cell('Пробег на конец, км', 114, header: true),
                            ],
                            _cell('Полученный газ', 110, header: true),
                            _cell('Полученный бензин', 110, header: true),
                            _cell(
                              'Направление',
                              directionWidth,
                              header: true,
                              left: true,
                            ),
                          ],
                        ),
                        for (final d in r.days)
                          Row(
                            children: [
                              if (_distance)
                                _cell(
                                  '${_number(d.km)}${d.pending > 0 ? ' *' : ''}',
                                  114,
                                )
                              else ...[
                                _cell(
                                  d.startKm == null ? '—' : _number(d.startKm!),
                                  114,
                                ),
                                _cell(
                                  d.endKm == null ? '—' : _number(d.endKm!),
                                  114,
                                ),
                              ],
                              _cell(d.gas == 0 ? '—' : _litres(d.gas), 110),
                              _cell(
                                d.petrol == 0 ? '—' : _litres(d.petrol),
                                110,
                              ),
                              _cell(
                                d.directions.isEmpty ? '—' : d.directions,
                                directionWidth,
                                left: true,
                              ),
                            ],
                          ),
                        Row(
                          children: [
                            _cell(
                              '${_number(r.km)} км',
                              _distance ? 114 : 228,
                              total: true,
                            ),
                            _cell(_litres(r.gas), 110, total: true),
                            _cell(_litres(r.petrol), 110, total: true),
                            _cell('', directionWidth, total: true, left: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (r.days.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'В этом месяце смен пока нет.',
                style: TextStyle(color: muted, fontSize: 14),
              ),
            ),
          if (r.pending > 0)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '* Учтён только сохранённый пробег. Незавершённые смены ещё могут изменить итог.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
        ],
      ),
      padding: EdgeInsets.zero,
    );
  }

  void _navigate(int index) {
    if (index == 2) {
      _showQuickAddMenu(context, widget.session);
      return;
    }
    Navigator.of(context).pop();
    widget.onNavigate(index);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now(), r = _report;
    final canNext = _month.isBefore(DateTime(now.year, now.month));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xC010161A),
                            border: Border.all(color: gold, width: .8),
                          ),
                          child: IconButton(
                            tooltip: 'Назад',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.chevron_left, color: gold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Отчёт за газ',
                            style: TextStyle(
                              color: Color(0xFFF1EEE6),
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: _panel(
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Предыдущий месяц',
                            onPressed: _busy ? null : () => _move(-1),
                            icon: const Icon(Icons.chevron_left, color: gold),
                          ),
                          Expanded(
                            child: Text(
                              _monthName(_month),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Следующий месяц',
                            onPressed: canNext && !_busy
                                ? () => _move(1)
                                : null,
                            icon: Icon(
                              Icons.chevron_right,
                              color: canNext ? gold : const Color(0xFF4B5357),
                            ),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: _error != null
                        ? Center(
                            child: _panel(
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
                          )
                        : r == null
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: gold,
                              strokeWidth: 2,
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                            children: [
                              _summary(r),
                              const SizedBox(height: 12),
                              _table(r),
                              const SizedBox(height: 12),
                              _status(r),
                            ],
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 3),
                    child: _MillDock(index: 4, onChanged: _navigate),
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
