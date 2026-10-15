part of 'app_shell.dart';

class _AdvanceReportScreen extends StatefulWidget {
  final AppSession session;
  const _AdvanceReportScreen({required this.session});
  @override
  State<_AdvanceReportScreen> createState() => _AdvanceReportScreenState();
}

class _AdvanceReportScreenState extends State<_AdvanceReportScreen> {
  static const gold = Color(0xFFCEA15B), muted = Color(0xFF90999E);
  late final AdvanceReportRepository _repository;
  AdvanceReportData? _data;
  AdvanceReport? _archive;
  bool _busy = false, _history = false, _expanded = false;
  String? _error;
  int _request = 0;
  AdvanceReport? get _report => _archive ?? _data?.current;
  @override
  void initState() {
    super.initState();
    _repository = AdvanceReportRepository(widget.session.ownerKey);
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
      final data = await _repository.load();
      if (mounted && request == _request)
        setState(() {
          _data = data;
          _error = null;
        });
    } catch (_) {
      if (mounted && request == _request)
        setState(() => _error = 'Не удалось загрузить авансовый отчёт.');
    }
  }

  void _notice(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _reload();
    } catch (e) {
      if (mounted)
        _notice(
          e.toString().replaceFirst(
            RegExp(r'^(Bad state: |Invalid argument\(s\): )'),
            '',
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _money(int value) =>
      '${AdvanceRow.decimal(value, 2, grouped: true)} ₸';
  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  Widget _text(
    String value, {
    double size = 13,
    Color color = const Color(0xFFE9EAEB),
    bool bold = false,
  }) => Text(
    value,
    style: TextStyle(
      fontSize: size,
      color: color,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
    ),
  );
  Widget _action(
    String title,
    VoidCallback? action, {
    IconData? icon,
  }) => TextButton(
    onPressed: _busy ? null : action,
    style: TextButton.styleFrom(
      foregroundColor: gold,
      minimumSize: const Size(40, 40),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
        Flexible(child: Text(title, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
  void _back() {
    if (_busy) return;
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }
    if (_archive != null) {
      setState(() {
        _archive = null;
        _history = true;
      });
      return;
    }
    if (_history) {
      setState(() => _history = false);
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _editCash() async {
    final report = _report;
    if (report == null || _archive != null || _busy) return;
    final controller = TextEditingController(
      text: AdvanceRow.decimal(report.received, 2),
    );
    String? error;
    final result = await showDialog<Object>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (c, update) => AlertDialog(
          backgroundColor: const Color(0xFF11181C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: const BorderSide(color: Color(0xFF776044), width: .8),
          ),
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Получено из кассы',
            style: TextStyle(fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _text(
                'Автоматически: ${_money(report.expenses)}. Введите фактически полученную сумму или вернитесь к автоматическому расчёту.',
                color: muted,
                size: 12,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Color(0xFFE9EAEB)),
                decoration: InputDecoration(
                  labelText: 'Фактически получено',
                  suffixText: '₸',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialog, 'auto'),
              child: const Text('Автоматически'),
            ),
            TextButton(
              onPressed: () {
                final value = AdvanceRow.parseDecimal(controller.text, 2);
                if (value == null || value > 99999999999) {
                  update(() => error = 'Введите сумму от 0 до 999 999 999,99');
                  return;
                }
                Navigator.pop(dialog, value);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (mounted && result != null)
      await _run(
        () => _repository.setCash(result == 'auto' ? null : result as int),
      );
  }

  Future<void> _editExpense([AdvanceRow? row]) async {
    if (_busy || _archive != null) return;
    if (row?.automatic == true) {
      final source = row!;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF11181C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: const BorderSide(color: Color(0xFF776044), width: .8),
          ),
          surfaceTintColor: Colors.transparent,
          title: const Text('Суточные из рейса'),
          content: Text(
            '${source.direction} · ${_date(source.date)}\n1 × ${_money(source.price)} = ${_money(source.total)}\n\nСтрока обновляется вместе с исходным рейсом.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Закрыть'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(c);
                _openDaySummary(context, source.date);
              },
              child: const Text('Открыть сводку дня'),
            ),
          ],
        ),
      );
      return;
    }
    final result = await showModalBottomSheet<AdvanceRow>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _AdvanceExpenseEditor(row: row),
    );
    if (mounted && result != null)
      await _run(() => _repository.saveExpense(result));
  }

  Future<void> _delete(AdvanceRow row) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF11181C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: Color(0xFF776044), width: .8),
        ),
        surfaceTintColor: Colors.transparent,
        title: const Text('Удалить расход?'),
        content: Text('${row.name} · ${_money(row.total)}'),
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
    if (mounted && yes == true)
      await _run(() => _repository.deleteExpense(row.id));
  }

  Future<void> _rowActions(AdvanceRow row) async {
    if (_busy || _archive != null) return;
    if (row.automatic) {
      await _editExpense(row);
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF11181C),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                row.name,
                style: const TextStyle(color: Color(0xFFE9EAEB)),
              ),
              subtitle: Text(_money(row.total)),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: gold),
              title: const Text('Изменить'),
              onTap: () => Navigator.pop(c, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: muted),
              title: const Text('Удалить'),
              onTap: () => Navigator.pop(c, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') await _editExpense(row);
    if (action == 'delete') await _delete(row);
  }

  Future<void> _submit() async {
    final report = _data?.current;
    if (_busy || report == null || report.rows.isEmpty || _error != null)
      return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF11181C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: Color(0xFF776044), width: .8),
        ),
        surfaceTintColor: Colors.transparent,
        title: const Text('Отчёт сдан?'),
        content: Text(
          'Зафиксировать отчёт № ${report.number}?\n\nПолучено: ${_money(report.received)}\nРасходы: ${_money(report.expenses)}\nОстаток: ${_money(report.balance)}\n\nОтчёт останется в истории. Новый начнётся с нуля; остаток автоматически не переносится.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Да, отчёт сдан'),
          ),
        ],
      ),
    );
    if (mounted && yes == true)
      await _run(() => _repository.submit(report.signature));
  }

  Widget _summary(AdvanceReport report) => _AdvanceMoreSurface(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        InkWell(
          onTap: _archive != null || _busy ? null : _editCash,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: _text('Получено из кассы', color: muted)),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _text(_money(report.received), size: 23, bold: true),
                  ),
                ),
                if (_archive == null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.edit_outlined, color: gold, size: 18),
                ],
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: Color(0xFF353A3D)),
        ),
        InkWell(
          onTap: _busy ? null : () => setState(() => _expanded = true),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: _text('Расходы', color: muted)),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _text(_money(report.expenses), size: 23, bold: true),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: gold, size: 20),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _menuAction(String title, IconData icon, VoidCallback? action) =>
      _AdvanceMoreSurface(
        padding: const EdgeInsets.all(8),
        child: TextButton(
          onPressed: _busy ? null : action,
          style: TextButton.styleFrom(
            foregroundColor: gold,
            disabledForegroundColor: muted.withValues(alpha: .45),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 23,
                height: 23,
                child: FittedBox(child: _CinematicMore.badge(icon, gold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFE9EAEB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFBDC3C5),
                size: 20,
              ),
            ],
          ),
        ),
      );

  Widget _table(AdvanceReport report) {
    Widget cell(
      String text, {
      bool header = false,
      bool total = false,
      bool left = false,
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      child: Text(
        text,
        textAlign: left ? TextAlign.left : TextAlign.center,
        softWrap: true,
        style: TextStyle(
          fontSize: header ? 9 : 10,
          height: 1.2,
          color: total
              ? gold
              : header
              ? muted
              : const Color(0xFFE9EAEB),
          fontWeight: total ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: const Color(0xFF353A3D), width: .5),
      columnWidths: const {
        0: FlexColumnWidth(5),
        1: FlexColumnWidth(12),
        2: FlexColumnWidth(23),
        3: FlexColumnWidth(9),
        4: FlexColumnWidth(14),
        5: FlexColumnWidth(16),
        6: FlexColumnWidth(21),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0x80161B1D)),
          children: [
            for (final title in [
              '№',
              'Дата',
              'Наименование',
              'Кол-\nво',
              'Цена',
              'Сумма',
              'Направление',
            ])
              cell(title, header: true),
          ],
        ),
        for (var i = 0; i < report.rows.length; i++)
          TableRow(
            children: [
              for (final value in [
                '${i + 1}',
                '${report.rows[i].date.day.toString().padLeft(2, '0')}.${report.rows[i].date.month.toString().padLeft(2, '0')}\n${report.rows[i].date.year}',
                report.rows[i].name,
                AdvanceRow.decimal(report.rows[i].quantity, 3),
                AdvanceRow.decimal(report.rows[i].price, 2, grouped: true),
                AdvanceRow.decimal(report.rows[i].total, 2, grouped: true),
                report.rows[i].direction.isEmpty
                    ? '—'
                    : report.rows[i].direction,
              ])
                InkWell(
                  onTap: _archive != null || _busy
                      ? null
                      : () => _rowActions(report.rows[i]),
                  child: cell(value),
                ),
            ],
          ),
        TableRow(
          decoration: const BoxDecoration(color: Color(0x701C211F)),
          children: [
            for (final value in [
              '',
              '',
              'Итого',
              '',
              '',
              AdvanceRow.decimal(report.expenses, 2, grouped: true),
              '₸',
            ])
              cell(value, total: true),
          ],
        ),
      ],
    );
  }

  Widget _body(AdvanceReport report) {
    if (_expanded) {
      return _AdvanceMoreSurface(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _text(
                    'Расходы · ${report.rows.length}',
                    size: 16,
                    bold: true,
                  ),
                ),
                _action('Закрыть', () => setState(() => _expanded = false)),
              ],
            ),
            if (_archive == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _text(
                  'Нажмите расход, чтобы изменить или удалить',
                  size: 11,
                  color: muted,
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: report.rows.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: _text('Расходов пока нет', color: muted),
                      )
                    : _table(report),
              ),
            ),
            if (_archive == null)
              _action('Добавить расход', () => _editExpense(), icon: Icons.add),
          ],
        ),
      );
    }
    return ListView(
      children: [
        if (_archive != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _text(
              'Сдан · № ${report.number} · ${_date(report.submittedAt!)}',
              color: muted,
              size: 12,
            ),
          ),
        _summary(report),
        const SizedBox(height: 12),
        if (_archive == null) ...[
          _menuAction('Добавить расход', Icons.add, () => _editExpense()),
          const SizedBox(height: 12),
        ],
        _menuAction('Открыть бланк', Icons.description_outlined, () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => _AdvanceImagePreview(
                report: report,
                name: widget.session.displayName,
              ),
            ),
          );
        }),
        if (_archive == null) ...[
          const SizedBox(height: 12),
          _menuAction(
            'Отчёт сдан',
            Icons.check_circle_outline,
            report.rows.isEmpty ? null : _submit,
          ),
        ],
      ],
    );
  }

  Widget _historyList() {
    final history = _data!.ledger.history;
    if (history.isEmpty)
      return Center(child: _text('Сданных отчётов пока нет', color: muted));
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (c, i) {
        final report = history[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: InkWell(
            onTap: () => setState(() {
              _archive = report;
              _history = false;
              _expanded = false;
            }),
            child: _AdvanceMoreSurface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _text(
                    'Отчёт № ${report.number} · ${_date(report.submittedAt!)}',
                    size: 16,
                    bold: true,
                  ),
                  const SizedBox(height: 7),
                  _text('Расходы ${_money(report.expenses)}', color: gold),
                  const SizedBox(height: 4),
                  _text(
                    '${report.rows.length} строк · остаток ${_money(report.balance)}',
                    size: 12,
                    color: muted,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _referenceScreen(AdvanceReport report) => PopScope(
    canPop: !_busy && _archive == null,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !_busy) _back();
    },
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF080E12),
        body: LayoutBuilder(
          builder: (context, box) {
            final scale = box.maxWidth / 1024;
            final height = box.maxHeight / scale;
            final safe = MediaQuery.paddingOf(context).top / scale;
            Widget at(double x, double y, double w, double h, Widget child) =>
                Positioned(
                  left: x,
                  top: y / 1536 * height,
                  width: w,
                  height: h / 1536 * height,
                  child: child,
                );
            Widget label(
              String text,
              double size, {
              Color color = const Color(0xFFEAEDEF),
              bool bold = false,
            }) => Text(
              text,
              style: TextStyle(
                fontSize: size,
                height: 1.15,
                color: color,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              ),
            );
            Widget tap(Widget child, VoidCallback? fn) => Material(
              color: Colors.transparent,
              child: InkWell(onTap: _busy ? null : fn, child: child),
            );
            Widget stat(
              String title,
              int value,
              IconData icon,
              Color color, {
              VoidCallback? onTap,
            }) => tap(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: const Color(0xFFE6B46B), size: 42),
                        const SizedBox(width: 15),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: label(title, 29),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: label(
                              _money(value),
                              48,
                              color: color,
                              bold: true,
                            ),
                          ),
                        ),
                        if (onTap != null)
                          const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Icon(
                              Icons.edit_outlined,
                              color: Color(0xFFE6B46B),
                              size: 28,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              onTap,
            );
            final start =
                report.start ??
                (report.rows.isEmpty ? DateTime.now() : report.rows.first.date);
            return SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: 1024,
                  height: height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/scenes/advance_report_reference.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                      Positioned(
                        left: 52,
                        top: math.max(safe + 12, height * 50 / 1536),
                        width: 78,
                        height: 78,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xDC080F14),
                            border: Border.all(
                              color: const Color(0xFFE6B46B),
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            onPressed: _busy ? null : _back,
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFFE6B46B),
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      at(
                        176,
                        65,
                        650,
                        66,
                        Align(
                          alignment: Alignment.centerLeft,
                          child: label('Авансовый отчёт', 43, bold: true),
                        ),
                      ),
                      at(
                        180,
                        132,
                        348,
                        70,
                        tap(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 17),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  color: Color(0xFFE6B46B),
                                  size: 32,
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      label('С ${_date(start)}', 26),
                                      label(
                                        _archive == null
                                            ? 'до следующей сдачи'
                                            : 'Сдан ${_date(report.submittedAt!)}',
                                        19,
                                        color: muted,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ],
                            ),
                          ),
                          () => setState(() {
                            _history = true;
                            _archive = null;
                          }),
                        ),
                      ),
                      at(
                        220,
                        280,
                        264,
                        145,
                        stat(
                          'Получено\nиз кассы',
                          report.received,
                          Icons.payments_outlined,
                          const Color(0xFFE6B46B),
                          onTap: _archive == null ? _editCash : null,
                        ),
                      ),
                      at(
                        490,
                        280,
                        230,
                        145,
                        stat(
                          'Расход',
                          report.expenses,
                          Icons.account_balance_wallet_outlined,
                          const Color(0xFFEAEDEF),
                          onTap: () => setState(() => _expanded = true),
                        ),
                      ),
                      at(
                        730,
                        280,
                        177,
                        145,
                        stat(
                          'Остаток',
                          report.balance,
                          Icons.pie_chart_outline,
                          report.balance < 0
                              ? const Color(0xFFD59C89)
                              : const Color(0xFF39AB79),
                        ),
                      ),
                      at(
                        482,
                        280,
                        1,
                        142,
                        Container(color: const Color(0x70776044)),
                      ),
                      at(
                        720,
                        280,
                        1,
                        142,
                        Container(color: const Color(0x70776044)),
                      ),
                      at(
                        76,
                        612,
                        540,
                        70,
                        Row(
                          children: [
                            const Icon(
                              Icons.receipt_long_outlined,
                              color: Color(0xFFE6B46B),
                              size: 44,
                            ),
                            const SizedBox(width: 20),
                            label('Список расходов', 31),
                          ],
                        ),
                      ),
                      if (_archive == null)
                        at(
                          700,
                          618,
                          250,
                          61,
                          tap(
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE6B46B),
                                  width: 2,
                                ),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xB0553416),
                                    Color(0xD0101619),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: label(
                                  '+  Добавить расход',
                                  25,
                                  color: const Color(0xFFE6B46B),
                                ),
                              ),
                            ),
                            () => _editExpense(),
                          ),
                        ),
                      at(
                        56,
                        696,
                        912,
                        550,
                        Column(
                          children: [
                            _referenceRow(null, 0),
                            Expanded(
                              child: report.rows.isEmpty
                                  ? Center(
                                      child: label(
                                        'Расходов пока нет',
                                        28,
                                        color: muted,
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: report.rows.length,
                                      itemBuilder: (_, i) => tap(
                                        _referenceRow(report.rows[i], i + 1),
                                        _archive == null
                                            ? () => _rowActions(report.rows[i])
                                            : null,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      at(
                        60,
                        1307,
                        435,
                        128,
                        tap(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  color: Color(0xFFE6B46B),
                                  size: 60,
                                ),
                                const SizedBox(width: 25),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      label(
                                        'Открыть бланк',
                                        29,
                                        color: const Color(0xFFE6B46B),
                                      ),
                                      const SizedBox(height: 8),
                                      label(
                                        'Полный отчёт для сдачи',
                                        20,
                                        color: muted,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFFE6B46B),
                                  size: 34,
                                ),
                              ],
                            ),
                          ),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => _AdvanceImagePreview(
                                report: report,
                                name: widget.session.displayName,
                              ),
                            ),
                          ),
                        ),
                      ),
                      at(
                        530,
                        1307,
                        440,
                        128,
                        tap(
                          Opacity(
                            opacity: report.rows.isEmpty ? 0.5 : 1.0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 35,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.task_alt,
                                    color: Color(0xFF20180D),
                                    size: 62,
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        label(
                                          _archive == null
                                              ? 'Отчёт сдан'
                                              : 'Сданный отчёт',
                                          29,
                                          color: const Color(0xFF20180D),
                                        ),
                                        const SizedBox(height: 8),
                                        label(
                                          _archive == null
                                              ? 'Зафиксировать и начать новый'
                                              : 'Открыт из истории',
                                          19,
                                          color: const Color(0xFF302314),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _archive == null && report.rows.isNotEmpty
                              ? _submit
                              : null,
                        ),
                      ),
                      if (_busy)
                        at(
                          55,
                          1468,
                          915,
                          5,
                          const LinearProgressIndicator(
                            color: Color(0xFFE6B46B),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _referenceRow(AdvanceRow? row, int index) {
    final header = row == null;
    Widget cell(String value, int flex, {Color? color, bool left = false}) =>
        Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              value,
              textAlign: left ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                fontSize: header ? 21 : 23,
                height: 1.2,
                color: color ?? (header ? muted : const Color(0xFFEAEDEF)),
              ),
            ),
          ),
        );
    return Container(
      constraints: BoxConstraints(minHeight: header ? 54 : 78),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: header ? const Color(0xCC20282C) : const Color(0x35081013),
        border: const Border(bottom: BorderSide(color: Color(0xFF303639))),
      ),
      child: Row(
        children: [
          cell(header ? '№' : '$index', 5),
          cell(header ? 'Дата' : _date(row.date).substring(0, 5), 9),
          if (!header)
            Icon(
              row.automatic ? Icons.location_on_outlined : Icons.build_outlined,
              color: const Color(0xFFE6B46B),
              size: 29,
            ),
          cell(
            header ? 'Наименование' : row.name,
            header ? 25 : 22,
            left: true,
          ),
          cell(header ? 'Кол-во' : AdvanceRow.decimal(row.quantity, 3), 10),
          cell(header ? 'Цена' : _money(row.price), 12),
          cell(
            header ? 'Сумма' : _money(row.total),
            13,
            color: header ? muted : const Color(0xFFE6B46B),
          ),
          cell(
            header
                ? 'Направление'
                : row.direction.isEmpty
                ? '—'
                : row.direction,
            20,
            left: true,
          ),
          SizedBox(
            width: 28,
            child: header
                ? const SizedBox.shrink()
                : const Icon(
                    Icons.more_vert,
                    color: Color(0xFFE6B46B),
                    size: 27,
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      _data != null && !_history && !_expanded && _error == null
      ? _referenceScreen(_report!)
      : PopScope(
          canPop: !_busy && !_history && _archive == null && !_expanded,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && !_busy) _back();
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.light,
            ),
            child: Scaffold(
              backgroundColor: const Color(0xFF101517),
              body: Stack(
                children: [
                  _CinematicMore.backdrop(),
                  SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Назад',
                                onPressed: _busy ? null : _back,
                                icon: const Icon(Icons.arrow_back, color: gold),
                              ),
                              Expanded(
                                child: _text(
                                  _history
                                      ? 'История отчётов'
                                      : 'Авансовый отчёт',
                                  size: 22,
                                  bold: true,
                                ),
                              ),
                              if (!_history && _archive == null)
                                IconButton(
                                  tooltip: 'История отчётов',
                                  onPressed: _busy || _data == null
                                      ? null
                                      : () => setState(() {
                                          _history = true;
                                          _expanded = false;
                                        }),
                                  icon: const Icon(Icons.history, color: gold),
                                ),
                            ],
                          ),
                        ),
                        if (_busy)
                          const LinearProgressIndicator(
                            minHeight: 2,
                            color: gold,
                            backgroundColor: Colors.transparent,
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                            child: _error != null
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _text(_error!),
                                        _action('Повторить', _reload),
                                      ],
                                    ),
                                  )
                                : _data == null
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: gold,
                                    ),
                                  )
                                : _history
                                ? _historyList()
                                : _body(_report!),
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

class _AdvanceExpenseEditor extends StatefulWidget {
  final AdvanceRow? row;
  const _AdvanceExpenseEditor({this.row});
  @override
  State<_AdvanceExpenseEditor> createState() => _AdvanceExpenseEditorState();
}

class _AdvanceExpenseEditorState extends State<_AdvanceExpenseEditor> {
  late final TextEditingController _name, _quantity, _price, _direction;
  late DateTime _date;
  String? _error;
  @override
  void initState() {
    super.initState();
    final row = widget.row;
    _date = row?.date ?? DateTime.now();
    _name = TextEditingController(text: row?.name ?? '');
    _quantity = TextEditingController(
      text: row == null ? '1' : AdvanceRow.decimal(row.quantity, 3),
    );
    _price = TextEditingController(
      text: row == null ? '' : AdvanceRow.decimal(row.price, 2),
    );
    _direction = TextEditingController(text: row?.direction ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _price.dispose();
    _direction.dispose();
    super.dispose();
  }

  void _save() {
    final quantity = AdvanceRow.parseDecimal(_quantity.text, 3),
        price = AdvanceRow.parseDecimal(_price.text, 2);
    if (quantity == null || quantity <= 0 || price == null) {
      setState(
        () => _error = 'Укажите количество больше нуля и корректную цену',
      );
      return;
    }
    final row = AdvanceRow(
      id: widget.row?.id ?? 'manual:${DateTime.now().microsecondsSinceEpoch}',
      date: _date,
      name: _name.text.trim(),
      quantity: quantity,
      price: price,
      direction: _direction.text.trim(),
    );
    try {
      row.validate();
    } catch (_) {
      setState(() => _error = 'Проверьте наименование, количество и цену');
      return;
    }
    Navigator.pop(context, row);
  }

  @override
  Widget build(BuildContext context) {
    final quantity = AdvanceRow.parseDecimal(_quantity.text, 3) ?? 0,
        price = AdvanceRow.parseDecimal(_price.text, 2) ?? 0;
    Widget field(
      TextEditingController controller,
      String title, {
      bool numeric = false,
      int? maxLength,
    }) => TextField(
      controller: controller,
      maxLength: maxLength,
      textCapitalization: numeric
          ? TextCapitalization.none
          : TextCapitalization.sentences,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: Color(0xFFE9EAEB), fontSize: 15),
      onChanged: (_) => setState(() => _error = null),
      decoration: InputDecoration(
        labelText: title,
        counterText: '',
        labelStyle: const TextStyle(color: Color(0xFF90999E)),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF6C604D)),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        10,
        0,
        10,
        MediaQuery.viewInsetsOf(context).bottom + 8,
      ),
      child: SingleChildScrollView(
        child: _AdvanceMoreSurface(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.row == null ? 'Новый расход' : 'Изменить расход',
                style: const TextStyle(
                  color: Color(0xFFE9EAEB),
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (selected != null && mounted)
                    setState(() => _date = selected);
                },
                icon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Color(0xFFCEA15B),
                ),
                label: Text(
                  '${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}',
                  style: const TextStyle(color: Color(0xFFCEA15B)),
                ),
              ),
              field(_name, 'Наименование', maxLength: 160),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: field(_quantity, 'Количество', numeric: true),
                  ),
                  const SizedBox(width: 18),
                  Expanded(child: field(_price, 'Цена, ₸', numeric: true)),
                ],
              ),
              const SizedBox(height: 10),
              field(_direction, 'Направление (необязательно)', maxLength: 120),
              const SizedBox(height: 18),
              Text(
                'Сумма: ${quantity <= 999999999 && price <= 99999999999 ? AdvanceRow.decimal(AdvanceRow.calculateTotal(quantity, price), 2, grouped: true) : '—'} ₸',
                style: const TextStyle(
                  color: Color(0xFFE9EAEB),
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFD29280)),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Отмена',
                      style: TextStyle(color: Color(0xFF90999E)),
                    ),
                  ),
                  TextButton(
                    onPressed: _save,
                    child: const Text(
                      'Сохранить',
                      style: TextStyle(color: Color(0xFFCEA15B)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Match More panels while preserving the report's existing content bounds.
class _AdvanceMoreSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _AdvanceMoreSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: _CinematicMore.panel(),
    child: Padding(padding: padding, child: child),
  );
}

class _AdvanceImagePreview extends StatefulWidget {
  final AdvanceReport report;
  final String name;
  const _AdvanceImagePreview({required this.report, required this.name});
  @override
  State<_AdvanceImagePreview> createState() => _AdvanceImagePreviewState();
}

class _AdvanceImagePreviewState extends State<_AdvanceImagePreview> {
  static const _channel = MethodChannel('melnitsa/advance_image');
  int _page = 0;
  bool _loading = true, _saving = false;
  dynamic _bytes;
  String? _error;
  late final DateTime _end = widget.report.submittedAt ?? DateTime.now();
  int get _pages => math.max(1, (widget.report.rows.length + 15) ~/ 16);
  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  @override
  void initState() {
    super.initState();
    _render();
  }

  Future<void> _render() async {
    setState(() {
      _loading = true;
      _error = null;
      _bytes = null;
    });
    try {
      final r = widget.report;
      final daily = <String, List<AdvanceRow>>{};
      final ordered = List<AdvanceRow>.of(r.rows)
        ..sort((a, b) => a.date.compareTo(b.date));
      for (final row in ordered) {
        daily.putIfAbsent(_date(row.date), () => []).add(row);
      }
      final days = daily.entries.toList();
      final data = await _channel.invokeMethod<dynamic>('render', {
        'name': widget.name,
        'number': '${r.number}',
        'period': '${r.start == null ? '—' : _date(r.start!)} — ${_date(_end)}',
        'daily': [
          for (final day in days.skip(_page * 16).take(16))
            [
              day.key,
              day.value
                  .map((row) => AdvanceRow.decimal(row.total, 2, grouped: true))
                  .join(' + '),
              AdvanceRow.decimal(
                day.value.fold<int>(0, (sum, row) => sum + row.total),
                2,
                grouped: true,
              ),
            ],
        ],
        'dailyContinues': days.length > (_page + 1) * 16,
        'received': AdvanceRow.decimal(r.received, 2, grouped: true),
        'expenses': AdvanceRow.decimal(r.expenses, 2, grouped: true),
        'balance': AdvanceRow.decimal(r.balance, 2, grouped: true),
        'page': '${_page + 1}',
        'pages': '$_pages',
        'status': r.submittedAt == null
            ? 'Текущий отчёт'
            : 'Сдан ${_date(r.submittedAt!)}',
        'rows': [
          for (
            var i = _page * 16;
            i < math.min(r.rows.length, (_page + 1) * 16);
            i++
          )
            [
              '${i + 1}',
              _date(r.rows[i].date),
              r.rows[i].name,
              AdvanceRow.decimal(r.rows[i].quantity, 3),
              AdvanceRow.decimal(r.rows[i].price, 2, grouped: true),
              AdvanceRow.decimal(r.rows[i].total, 2, grouped: true),
              r.rows[i].direction,
            ],
        ],
      });
      if (mounted)
        setState(() {
          _bytes = data;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Не удалось создать бланк: $e';
        });
    }
  }

  Future<void> _saveImage() async {
    if (_bytes == null || _saving) return;
    setState(() => _saving = true);
    try {
      final saved = await _channel.invokeMethod<bool>('save', {
        'bytes': _bytes,
      });
      if (mounted && saved == true)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Картинка сохранена')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Не удалось сохранить: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      backgroundColor: const Color(0xFF111619),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111619),
        foregroundColor: Colors.white,
        title: const Text('Бланк отчёта'),
        automaticallyImplyLeading: !_saving,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.white),
                            ),
                            TextButton(
                              onPressed: _render,
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : InteractiveViewer(
                      key: ValueKey(_page),
                      minScale: 1,
                      maxScale: 6,
                      child: Center(
                        child: Image.memory(_bytes, fit: BoxFit.contain),
                      ),
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _loading || _saving || _page == 0
                      ? null
                      : () {
                          _page--;
                          _render();
                        },
                  icon: const Icon(Icons.chevron_left),
                  color: _CinematicMore.gold,
                ),
                Text(
                  'Лист ${_page + 1} из $_pages',
                  style: const TextStyle(color: Colors.white),
                ),
                IconButton(
                  onPressed: _loading || _saving || _page + 1 == _pages
                      ? null
                      : () {
                          _page++;
                          _render();
                        },
                  icon: const Icon(Icons.chevron_right),
                  color: _CinematicMore.gold,
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _loading || _saving || _bytes == null
                  ? null
                  : _saveImage,
              icon: const Icon(Icons.save_alt),
              label: Text(
                _saving ? 'Сохранение…' : 'Сохранить этот лист как картинку',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
