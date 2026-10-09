part of 'app_shell.dart';

class _ServiceHoodTarget extends StatefulWidget {
  final AppSession session;
  const _ServiceHoodTarget({required this.session});
  @override
  State<_ServiceHoodTarget> createState() => _ServiceHoodTargetState();
}

class _ServiceHoodTargetState extends State<_ServiceHoodTarget> {
  bool _opening = false;
  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await _openMaintenance(context, widget.session);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'ТО и обслуживание',
    child: _GarageTap(
      label: 'Открыть капот: ТО и обслуживание',
      onTap: _open,
      child: Center(
        child: Container(
          width: 78,
          height: 39,
          decoration: BoxDecoration(
            color: const Color(0x9909161C),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _amber.withValues(alpha: .8)),
            boxShadow: const [
              BoxShadow(color: Color(0x44FFA221), blurRadius: 12),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _opening
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _amber,
                      ),
                    )
                  : const _GarageIcon('oil', color: _amber, size: 24),
              const SizedBox(width: 7),
              _garageText('ТО', 19, color: _amber),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _openMaintenance(
  BuildContext context,
  AppSession session, {
  String? initialItem,
}) async {
  try {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _MaintenancePage(
          session: session,
          animation: const AlwaysStoppedAnimation(1),
          initialItem: initialItem,
        ),
      ),
    );
    _homeDataRevision.value++;
  } catch (e) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть обслуживание. Повторите попытку.'),
        ),
      );
  }
}

double _servicePhase(double t, double start, double end) =>
    ((t - start) / (end - start)).clamp(0.0, 1.0).toDouble();
String _serviceDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
String _serviceKm(int? value) =>
    value == null ? '—' : '${_fmtInt(value.toDouble())} км';
int _serviceDays(DateTime date) {
  final now = DateTime.now();
  return date.difference(DateTime(now.year, now.month, now.day)).inDays;
}

typedef _ServicePlace = Widget Function(
  double x,
  double y,
  double w,
  double h,
  Widget child,
);

class _MaintenancePage extends StatefulWidget {
  final AppSession session;
  final Animation<double> animation;
  final String? initialItem;
  const _MaintenancePage({
    required this.session,
    required this.animation,
    this.initialItem,
  });
  @override
  State<_MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<_MaintenancePage> {
  late final MaintenanceRepository _repository;
  MaintenanceBook? _book;
  String? _error;
  String? _filter;
  int _loadId = 0;
  @override
  void initState() {
    super.initState();
    _repository = MaintenanceRepository(widget.session.login);
    _filter = widget.initialItem;
    TestStore.revision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    TestStore.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final id = ++_loadId;
    try {
      final book = await _repository.load();
      if (mounted && id == _loadId)
        setState(() {
          _book = book;
          _error = null;
        });
    } catch (_) {
      if (mounted && id == _loadId)
        setState(
          () => _error = 'Не удалось прочитать историю. Повторите загрузку.',
        );
    }
  }

  Future<void> _record(MaintenanceItem item, {MaintenanceEntry? entry}) async {
    if (_book == null) return;
    await showModalBottomSheet<MaintenanceBook>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MaintenanceEntryForm(
        item: item,
        book: _book!,
        repository: _repository,
        entry: entry,
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _add() async {
    final item = await showModalBottomSheet<MaintenanceItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF11191D),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Что сделали?',
                  style: TextStyle(fontSize: 22, color: _paper),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final item in MaintenanceCatalog.items.where(
                      (item) => !item.usesDate,
                    ))
                      ListTile(
                        leading: _ServiceIcon(
                          item.icon,
                          size: 24,
                          color: _amber,
                        ),
                        title: Text(
                          item.id.startsWith('other_')
                              ? 'Другая работа · ${item.category}'
                              : item.title,
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: _amber,
                        ),
                        onTap: () => Navigator.pop(context, item),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (item != null && mounted) await _record(item);
  }

  bool _makingBlank = false;

  Future<void> _openBlank() async {
    if (_makingBlank) return;
    _makingBlank = true;
    try {
      final now = DateUtils.dateOnly(DateTime.now());
      var mode = 'month';
      var month = DateTime(now.year, now.month);
      var day = now;
      var range = DateTimeRange(start: now, end: now);
      final period = await showDialog<DateTimeRange>(
        context: context,
        builder: (dialog) => StatefulBuilder(
          builder: (dialog, update) {
            return AlertDialog(
              backgroundColor: const Color(0xFF11191D),
              title: const Text('Бланк обслуживания'),
              content: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: mode,
                      dropdownColor: const Color(0xFF11191D),
                      decoration: const InputDecoration(labelText: 'Период'),
                      items: const [
                        DropdownMenuItem(
                          value: 'month',
                          child: Text('За месяц'),
                        ),
                        DropdownMenuItem(value: 'day', child: Text('За день')),
                        DropdownMenuItem(
                          value: 'range',
                          child: Text('Произвольный период'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) update(() => mode = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    if (mode == 'month')
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => update(
                              () =>
                                  month = DateTime(month.year, month.month - 1),
                            ),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Text(
                              '${_garageMonths[month.month - 1]} ${month.year}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            onPressed: () => update(
                              () =>
                                  month = DateTime(month.year, month.month + 1),
                            ),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      )
                    else
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          mode == 'day'
                              ? _serviceDate(day)
                              : '${_serviceDate(range.start)} — ${_serviceDate(range.end)}',
                        ),
                        onPressed: () async {
                          if (mode == 'day') {
                            final picked = await showDatePicker(
                              context: dialog,
                              initialDate: day,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100, 12, 31),
                            );
                            if (picked != null && dialog.mounted)
                              update(() => day = picked);
                          } else {
                            final picked = await showDateRangePicker(
                              context: dialog,
                              initialDateRange: range,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100, 12, 31),
                              helpText: 'Период обслуживания',
                              saveText: 'Выбрать',
                            );
                            if (picked != null && dialog.mounted)
                              update(() => range = picked);
                          }
                        },
                      ),
                    const SizedBox(height: 10),
                    const Text(
                      'Дата, пробег, вид работы и что сделано. Все работы выбранного периода.',
                      style: TextStyle(color: _muted, fontSize: 13),
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
                  onPressed: () => Navigator.pop(
                    dialog,
                    mode == 'month'
                        ? DateTimeRange(
                            start: month,
                            end: DateTime(month.year, month.month + 1, 0),
                          )
                        : mode == 'day'
                        ? DateTimeRange(start: day, end: day)
                        : range,
                  ),
                  child: const Text('Создать бланк'),
                ),
              ],
            );
          },
        ),
      );
      if (period == null || !mounted) return;
      final book = await _repository.load();
      if (!mounted) return;
      final endExclusive = DateTime(
        period.end.year,
        period.end.month,
        period.end.day + 1,
      );
      final entries =
          book.entries
              .where(
                (e) =>
                    !e.example &&
                    !MaintenanceCatalog.byId(e.itemId).usesDate &&
                    !e.date.isBefore(period.start) &&
                    e.date.isBefore(endExclusive),
              )
              .toList()
            ..sort((a, b) {
              final d = a.date.compareTo(b.date);
              return d == 0 ? a.id.compareTo(b.id) : d;
            });
      if (entries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'За выбранный период работ нет. Выберите другой период.',
            ),
          ),
        );
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => _MaintenanceBlankPreview(
            entries: entries,
            period: period,
            name: widget.session.displayName,
          ),
        ),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось подготовить бланк. Повторите попытку.'),
          ),
        );
    } finally {
      _makingBlank = false;
    }
  }

  static const _gold = Color(0xFFE6B46B);
  static const _white = Color(0xFFEAEDEF);
  static const _muted = Color(0xFFA7B0B6);
  static const _sceneAsset = 'assets/images/scenes/maintenance_reference.png';
  bool _newestFirst = true;

  @override
  Widget build(BuildContext context) {
    final book = _book;
    final oil = book?.latest('oil');
    final oilInterval = oil?.nextKm == null
        ? 10000
        : oil!.nextKm! - oil.odometer;
    final remaining = oil == null
        ? null
        : oil.odometer + oilInterval - book!.odometer;
    final allRows =
        (book?.entries ?? <MaintenanceEntry>[])
            .where(
              (e) => !MaintenanceCatalog.byId(e.itemId).usesDate && !e.example,
            )
            .toList()
          ..sort((a, b) {
            final d = b.date.compareTo(a.date);
            return d == 0 ? b.id.compareTo(a.id) : d;
          });
    final last = allRows.isEmpty ? null : allRows.first;
    final rows = allRows
        .where((e) => _filter == null || e.itemId == _filter)
        .toList();
    if (!_newestFirst) {
      final ascending = rows.reversed.toList();
      rows
        ..clear()
        ..addAll(ascending);
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
        body: LayoutBuilder(
          builder: (context, box) {
            final sx = box.maxWidth / 864;
            final top = math.max(
              0.0,
              MediaQuery.paddingOf(context).top - 56 * sx,
            );
            final height = math.max(box.maxHeight, 1536 * sx + top);
            // Uniform header and truck scaling; rectangular panels take extra height.
            final stretch = (height - top - 440 * sx) / 1096;
            double y(double value) {
              if (value <= 150) return top + value * sx;
              if (value <= 545) return top + 150 * sx + (value - 150) * stretch;
              if (value <= 835)
                return top + 150 * sx + 395 * stretch + (value - 545) * sx;
              return top + 440 * sx + 395 * stretch + (value - 835) * stretch;
            }

            Widget at(double x, double yy, double w, double h, Widget child) =>
                Positioned(
                  left: x * sx,
                  top: y(yy),
                  width: w * sx,
                  height: y(yy + h) - y(yy),
                  child: child,
                );
            // All oil-panel elements share the same plane as its metal frame.
            // The right edge of the reference is 8 px lower over 660 px.
            Widget oilAt(
              double x,
              double yy,
              double w,
              double h,
              Widget child,
            ) => at(
              x,
              yy + (x - 135) * 8 / 660,
              w,
              h,
              Transform(
                alignment: Alignment.topLeft,
                transform: Matrix4.identity()
                  ..setEntry(1, 0, (8 / 660) * stretch / sx),
                child: child,
              ),
            );
            Widget historySurface(Widget child) => LayoutBuilder(
              builder: (_, panel) {
                final tx = panel.maxWidth / 620;
                final ty = panel.maxHeight / 195;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8 * sx),
                  child: Stack(
                    children: [
                      // A clean metal surface, without painted rows or a flat black gap.
                      Positioned(
                        left: -125 * tx,
                        top: -195 * ty,
                        width: 864 * tx,
                        height: 1536 * ty,
                        child: Image.asset(_sceneAsset, fit: BoxFit.fill),
                      ),
                      Positioned.fill(child: child),
                    ],
                  ),
                );
              },
            );
            Widget slice(double start, double end) {
              final factor = (y(end) - y(start)) / (end - start);
              return Positioned(
                left: 0,
                right: 0,
                top: y(start),
                height: y(end) - y(start),
                child: ClipRect(
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: -start * factor,
                        height: 1536 * factor,
                        child: Image.asset(_sceneAsset, fit: BoxFit.fill),
                      ),
                    ],
                  ),
                ),
              );
            }

            Widget label(
              String value,
              double size, {
              Color color = _white,
              bool bold = false,
              Alignment align = Alignment.centerLeft,
            }) => Align(
              alignment: align,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: size * sx,
                    height: 1.12,
                    color: color,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            );
            Widget tap(Widget child, VoidCallback? action, String title) =>
                Semantics(
                  button: true,
                  label: title,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: action,
                      borderRadius: BorderRadius.circular(12 * sx),
                      splashColor: _gold.withValues(alpha: .14),
                      child: child,
                    ),
                  ),
                );
            Widget smallStat(
              IconData icon,
              String title,
              String value,
              String detail,
            ) => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 17 * sx,
                vertical: 13 * stretch,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: _gold, size: 38 * sx),
                  SizedBox(width: 14 * sx),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: label(title, 19, color: _muted)),
                        Expanded(child: label(value, 27, bold: true)),
                        if (detail.isNotEmpty)
                          Expanded(child: label(detail, 19, color: _muted)),
                      ],
                    ),
                  ),
                ],
              ),
            );
            Widget entryTile(MaintenanceEntry entry) {
              final item = MaintenanceCatalog.byId(entry.itemId);
              return SizedBox(
                height: 116 * stretch,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (_, tile) {
                          // Reuse the exact reference frame for every live history row.
                          final tx = tile.maxWidth / 745;
                          final ty = tile.maxHeight / 116;
                          return ClipRect(
                            child: Stack(
                              children: [
                                Positioned(
                                  left: -60 * tx,
                                  top: -972 * ty,
                                  width: 864 * tx,
                                  height: 1536 * ty,
                                  child: Image.asset(
                                    _sceneAsset,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: tap(
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            42 * sx,
                            14 * stretch,
                            76 * sx,
                            13 * stretch,
                          ),
                          child: Row(
                            children: [
                              _ServiceIcon(
                                item.icon,
                                color: _gold,
                                size: 59 * sx,
                              ),
                              SizedBox(width: 26 * sx),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: label(
                                        item.id.startsWith('other_')
                                            ? entry.note
                                            : item.title,
                                        27,
                                        bold: true,
                                      ),
                                    ),
                                    Expanded(
                                      child: label(
                                        '${_serviceDate(entry.date)} · ${_serviceKm(entry.odometer)}',
                                        23,
                                        color: _muted,
                                      ),
                                    ),
                                    if (!item.id.startsWith('other_') &&
                                        entry.note.isNotEmpty)
                                      Expanded(
                                        child: label(
                                          entry.note,
                                          23,
                                          color: _muted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        () => _record(item, entry: entry),
                        'Изменить ${item.title}',
                      ),
                    ),
                    Positioned(
                      right: 23 * sx,
                      top: 15 * stretch,
                      bottom: 15 * stretch,
                      child: PopupMenuButton<String>(
                        tooltip: 'Действия с записью',
                        color: const Color(0xFF11191D),
                        icon: Icon(
                          Icons.more_vert,
                          color: _gold,
                          size: 36 * sx,
                        ),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Изменить')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Удалить'),
                          ),
                        ],
                        onSelected: (v) async {
                          if (v == 'edit') {
                            await _record(item, entry: entry);
                            return;
                          }
                          if (await _testConfirm(
                                context,
                                'Удалить запись обслуживания?',
                              ) &&
                              mounted) {
                            await _testRun(context, () async {
                              await _repository.delete(entry.id);
                              await _load();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            final oilCaption = remaining == null
                ? 'Добавьте последнюю замену'
                : remaining > 0
                ? 'До замены ${_fmtInt(remaining.toDouble())} км'
                : remaining == 0
                ? 'Пора менять масло'
                : 'Просрочено на ${_fmtInt((-remaining).toDouble())} км';
            final progress = oil == null || book == null
                ? 0.0
                : ((book.odometer - oil.odometer) / oilInterval)
                      .clamp(0.0, 1.0)
                      .toDouble();
            return SingleChildScrollView(
              physics: height > box.maxHeight
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: box.maxWidth,
                height: height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        _sceneAsset,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                    slice(0, 150),
                    slice(150, 545),
                    slice(545, 835),
                    slice(835, 1536),
                    at(
                      59,
                      65,
                      80,
                      78,
                      tap(
                        Icon(
                          Icons.arrow_back_rounded,
                          color: _gold,
                          size: 40 * sx,
                        ),
                        () => Navigator.pop(context),
                        'Назад',
                      ),
                    ),
                    at(
                      734,
                      65,
                      80,
                      78,
                      tap(
                        Icon(
                          Icons.description_outlined,
                          color: _gold,
                          size: 40 * sx,
                        ),
                        _openBlank,
                        'Создать бланк обслуживания',
                      ),
                    ),
                    at(
                      204,
                      76,
                      506,
                      59,
                      label('ТО и обслуживание', 47, bold: true),
                    ),
                    if (book == null)
                      at(
                        100,
                        185,
                        660,
                        207,
                        Center(
                          child: _error == null
                              ? const CircularProgressIndicator(color: _gold)
                              : tap(
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: _white),
                                    ),
                                  ),
                                  _load,
                                  'Повторить загрузку',
                                ),
                        ),
                      )
                    else ...[
                      oilAt(
                        133,
                        204,
                        79,
                        58,
                        const _ServiceIcon('oil', color: _gold, size: 34),
                      ),
                      oilAt(
                        228,
                        202,
                        351,
                        34,
                        label('Замена масла', 29, color: _muted),
                      ),
                      oilAt(
                        604,
                        198,
                        146,
                        42,
                        tap(
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0x503A593B),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: const Color(0xFF74976B),
                                width: .7,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  oil == null
                                      ? Icons.add_circle_outline
                                      : Icons.check_circle,
                                  color: const Color(0xFFA2C397),
                                  size: 22 * sx,
                                ),
                                SizedBox(width: 6 * sx),
                                Flexible(
                                  child: label(
                                    oil == null ? 'Добавить' : 'Заменено',
                                    20,
                                    color: const Color(0xFFA2C397),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          () => _record(MaintenanceCatalog.byId('oil')),
                          'Записать замену масла',
                        ),
                      ),
                      oilAt(
                        226,
                        242,
                        516,
                        48,
                        label(
                          oilCaption,
                          41,
                          bold: true,
                          color: remaining != null && remaining <= 0
                              ? const Color(0xFFD59C89)
                              : _gold,
                        ),
                      ),
                      oilAt(
                        135,
                        294,
                        610,
                        19,
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF5A6368),
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(2 * sx),
                              child: LinearProgressIndicator(
                                value: progress,
                                color: _gold,
                                backgroundColor: const Color(0xFF252E34),
                                minHeight: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                      oilAt(
                        135,
                        327,
                        610,
                        29,
                        label(
                          oil == null
                              ? 'Последняя замена ещё не указана'
                              : '${_serviceDate(oil.date)} · ${_serviceKm(oil.odometer)} → ${_serviceKm(oil.odometer + oilInterval)}',
                          25,
                        ),
                      ),
                      oilAt(
                        135,
                        361,
                        610,
                        29,
                        label(
                          'Текущий пробег: ${_serviceKm(book.odometer)} · интервал ${_serviceKm(oilInterval)}',
                          23,
                          color: _muted,
                        ),
                      ),
                      at(
                        76,
                        432,
                        245,
                        99,
                        smallStat(
                          Icons.access_time_rounded,
                          'Последняя работа',
                          last == null ? '—' : _serviceDate(last.date),
                          last == null ? '' : _serviceKm(last.odometer),
                        ),
                      ),
                      at(
                        341,
                        432,
                        222,
                        99,
                        smallStat(
                          Icons.description_outlined,
                          'Работ в истории',
                          '${allRows.length}',
                          '',
                        ),
                      ),
                      at(
                        582,
                        432,
                        222,
                        99,
                        smallStat(
                          Icons.build_outlined,
                          'Следующее ТО',
                          oil == null
                              ? '—'
                              : _serviceKm(oil.odometer + oilInterval),
                          remaining == null
                              ? ''
                              : remaining > 0
                              ? 'через ${_serviceKm(remaining)}'
                              : 'пора обслужить',
                        ),
                      ),
                      if (_error != null)
                        at(
                          103,
                          549,
                          658,
                          41,
                          tap(
                            Container(
                              color: const Color(0xEA0B1115),
                              child: label(
                                _error!,
                                23,
                                color: const Color(0xFFD59C89),
                              ),
                            ),
                            _load,
                            'Повторить загрузку',
                          ),
                        ),
                      at(
                        74,
                        853,
                        231,
                        40,
                        label('История · ${rows.length}', 27),
                      ),
                      if (_filter != null)
                        at(
                          310,
                          853,
                          212,
                          40,
                          tap(
                            label('Все работы', 23, color: _gold),
                            () => setState(() => _filter = null),
                            'Все работы',
                          ),
                        ),
                      at(
                        570,
                        850,
                        217,
                        45,
                        PopupMenuButton<bool>(
                          tooltip: 'Порядок истории',
                          initialValue: _newestFirst,
                          color: const Color(0xFF11191D),
                          onSelected: (value) =>
                              setState(() => _newestFirst = value),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: true,
                              child: Text('Сначала новые'),
                            ),
                            PopupMenuItem(
                              value: false,
                              child: Text('Сначала старые'),
                            ),
                          ],
                          child: Row(
                            children: [
                              Icon(Icons.sort, color: _gold, size: 28 * sx),
                              SizedBox(width: 8 * sx),
                              Expanded(
                                child: label(
                                  _newestFirst
                                      ? 'Сначала новые'
                                      : 'Сначала старые',
                                  21,
                                  color: _gold,
                                ),
                              ),
                              Icon(
                                Icons.expand_more,
                                color: _gold,
                                size: 25 * sx,
                              ),
                            ],
                          ),
                        ),
                      ),
                      at(
                        60,
                        914,
                        745,
                        420,
                        historySurface(
                          rows.isEmpty
                              ? Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFF776044),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.all(28 * sx),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _filter != null
                                        ? 'По вашему запросу ничего не найдено.'
                                        : 'Записей нет. Добавьте выполненную работу.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 25 * sx,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  primary: false,
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  itemCount: rows.length,
                                  itemBuilder: (_, i) => entryTile(rows[i]),
                                ),
                        ),
                      ),
                      at(
                        150,
                        1358,
                        568,
                        98,
                        tap(
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 68 * sx,
                                height: 68 * sx,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _gold,
                                    width: 2 * sx,
                                  ),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 47 * sx,
                                  color: _gold,
                                ),
                              ),
                              SizedBox(width: 20 * sx),
                              Flexible(
                                child: label(
                                  'Добавить обслуживание',
                                  31,
                                  color: _gold,
                                  bold: true,
                                ),
                              ),
                            ],
                          ),
                          _add,
                          'Добавить обслуживание',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ServiceGlass extends StatelessWidget {
  final Widget child;
  final Color? accent;
  const _ServiceGlass({required this.child, this.accent});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(23),
      border: Border.all(
        color: accent ?? const Color(0xB57899A9),
        width: accent == null ? 1 : 1.5,
      ),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xC316252D), Color(0xDF071219), Color(0xB0132029)],
      ),
      boxShadow: accent == null
          ? null
          : [BoxShadow(color: accent!.withValues(alpha: .2), blurRadius: 17)],
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(23), child: child),
  );
}

class _ServiceButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool compact;
  const _ServiceButton({
    required this.label,
    required this.onTap,
    this.compact = false,
  });
  @override
  Widget build(BuildContext context) => _GarageTap(
    label: label,
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 22 : 24,
        vertical: compact ? 13 : 0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xD007131B),
        borderRadius: BorderRadius.circular(compact ? 15 : 24),
        border: Border.all(color: _amber, width: 1.7),
        boxShadow: [
          BoxShadow(
            color: _amber.withValues(alpha: compact ? 0.1 : 0.32),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!compact) ...[
            const _GarageIcon('plus', color: _amber, size: 46),
            const SizedBox(width: 24),
          ],
          _garageText(
            label,
            compact ? 23 : 34,
            color: _amber,
            weight: FontWeight.w500,
          ),
          if (compact) const Icon(Icons.chevron_right, color: _amber, size: 24),
        ],
      ),
    ),
  );
}

class _ServiceIcon extends StatelessWidget {
  final String kind;
  final Color color;
  final double size;
  const _ServiceIcon(this.kind, {this.color = _paper, this.size = 34});
  @override
  Widget build(BuildContext context) {
    if (kind == 'oil') return _GarageIcon('oil', color: color, size: size);
    final icon = switch (kind) {
      'filter' => Icons.filter_alt_outlined,
      'coolant' => Icons.water_drop_outlined,
      'battery' => Icons.battery_std,
      'belt' => Icons.settings_outlined,
      'brakes' => Icons.album_outlined,
      'tyre' => Icons.trip_origin,
      'document' => Icons.description_outlined,
      _ => Icons.build_outlined,
    };
    return Icon(icon, color: color, size: size);
  }
}

class _ServiceArc extends CustomPainter {
  final double ratio;
  const _ServiceArc(this.ratio);
  @override
  void paint(Canvas c, Size s) {
    final rect = Rect.fromLTWH(5, 5, s.width - 10, s.height - 10);
    for (var i = 0; i < 20; i++)
      c.drawArc(
        rect,
        math.pi * .8 + i * math.pi * 1.4 / 20,
        .16,
        false,
        Paint()
          ..color = i < ratio * 20 ? _amber : const Color(0xFF65717A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8,
      );
  }

  @override
  bool shouldRepaint(_ServiceArc old) => old.ratio != ratio;
}

class _ServiceLeaders extends CustomPainter {
  final bool oilOnly;
  const _ServiceLeaders({this.oilOnly = false});
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 840, size.height / (oilOnly ? 650 : 760));
    void line(Color color, Offset a, Offset b) {
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );
      c.drawCircle(
        b,
        20,
        Paint()
          ..color = color.withValues(alpha: .55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      c.drawCircle(
        b,
        13,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      c.drawCircle(b, 5, Paint()..color = color);
    }

    line(_amber, const Offset(274, 421), const Offset(315, 524));
    if (!oilOnly) {
      line(_ice, const Offset(619, 471), const Offset(591, 541));
      line(_ice, const Offset(181, 644), const Offset(183, 593));
      line(_paper, const Offset(680, 644), const Offset(666, 601));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_ServiceLeaders old) => old.oilOnly != oilOnly;
}

class _MaintenanceEntryForm extends StatefulWidget {
  final MaintenanceItem item;
  final MaintenanceBook book;
  final MaintenanceRepository repository;
  final MaintenanceEntry? entry;
  const _MaintenanceEntryForm({
    required this.item,
    required this.book,
    required this.repository,
    this.entry,
  });
  @override
  State<_MaintenanceEntryForm> createState() => _MaintenanceEntryFormState();
}

class _MaintenanceEntryFormState extends State<_MaintenanceEntryForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _at, _current;
  final _next = TextEditingController(),
      _cost = TextEditingController(),
      _note = TextEditingController();
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  DateTime? _nextDate;
  int _interval = 0;
  String? _autoNext;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _at = TextEditingController(text: '${widget.book.odometer}');
    _current = TextEditingController(text: '${widget.book.odometer}');
    final e = widget.entry;
    if (e != null) {
      _at.text = '${e.odometer}';
      _date = e.date;
      _next.text = e.nextKm?.toString() ?? '';
      _nextDate = e.nextDate;
      _cost.text = e.cost?.toString() ?? '';
      _note.text = e.note;
    } else {
      _at.addListener(_updateInterval);
      _applyInterval();
    }
  }

  void _updateInterval() {
    if (_interval <= 0 || widget.item.usesDate) return;
    if (_next.text.isEmpty || _next.text == _autoNext) {
      final km = int.tryParse(_at.text);
      if (km == null) return;
      _autoNext = '${km + _interval}';
      _next.text = _autoNext!;
    }
  }

  Future<void> _applyInterval() async {
    try {
      final b = await TestStore.load();
      if (!mounted) return;
      _interval =
          (b.calculationSettings['maintenance.${widget.item.id}'] as num?)
              ?.toInt() ??
          0;
      if (widget.item.id == 'oil' && _interval <= 0) _interval = 10000;
      if (_interval <= 0) return;
      setState(() {
        if (widget.item.usesDate) {
          _nextDate ??= _date.add(Duration(days: _interval));
        } else {
          _updateInterval();
        }
      });
    } catch (_) {
      if (mounted)
        setState(
          () => _error = 'Не удалось загрузить интервал. Укажите срок вручную.',
        );
    }
  }

  @override
  void dispose() {
    for (final c in [_at, _current, _next, _cost, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(bool next) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final value = await showDatePicker(
      context: context,
      initialDate: next
          ? (_nextDate ?? _date.add(const Duration(days: 365)))
          : _date,
      firstDate: next ? _date.add(const Duration(days: 1)) : DateTime(2000),
      lastDate: next ? DateTime(now.year + 20) : now,
    );
    if (value != null && mounted)
      setState(() {
        if (next) {
          _nextDate = value;
        } else {
          final autoDate =
              widget.entry == null &&
              _interval > 0 &&
              _nextDate == _date.add(Duration(days: _interval));
          _date = value;
          if (autoDate) _nextDate = value.add(Duration(days: _interval));
          if (_nextDate != null && !_nextDate!.isAfter(value)) _nextDate = null;
        }
      });
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (widget.item.usesDate && _nextDate == null) {
      setState(() => _error = 'Укажите срок действия');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final book = await widget.repository.record(
        itemId: widget.item.id,
        date: _date,
        entryId: widget.entry?.id,
        atKm: int.parse(_at.text),
        currentKm: math.max(int.parse(_current.text), int.parse(_at.text)),
        nextKm: int.tryParse(_next.text),
        nextDate: _nextDate,
        cost: double.tryParse(_cost.text.replaceAll(',', '.')),
        note: _note.text,
      );
      if (mounted) Navigator.of(context).pop(book);
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is ArgumentError
              ? '${e.message}'
              : 'Не удалось сохранить. Повторите попытку.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _number(
    TextEditingController c,
    String label, {
    bool optional = false,
    bool money = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: c,
      keyboardType: TextInputType.numberWithOptions(decimal: money),
      inputFormatters: money
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
          : [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: _paper),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (optional && (value ?? '').isEmpty) return null;
        final n = double.tryParse((value ?? '').replaceAll(',', '.'));
        return n == null || !n.isFinite || n < 0
            ? 'Введите корректное число'
            : null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          22,
          24,
          22,
          22 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF09151D),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: _amber.withValues(alpha: .6)),
        ),
        child: SingleChildScrollView(
          child: AbsorbPointer(
            absorbing: _saving,
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.item.title,
                    style: const TextStyle(color: _amber, fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Запись обслуживания',
                    style: TextStyle(color: _paper),
                  ),
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: () => _pick(false),
                    icon: const Icon(Icons.calendar_month),
                    label: Text('Дата: ${_serviceDate(_date)}'),
                  ),
                  _number(_at, 'Пробег при обслуживании, км'),
                  ExpansionTile(
                    title: const Text('Уточнить текущий пробег'),
                    children: [_number(_current, 'Текущий пробег, км')],
                  ),
                  if (widget.item.id == 'oil')
                    Text(
                      'Интервал замены — ${_fmtInt((_interval > 0 ? _interval : 10000).toDouble())} км.',
                      style: TextStyle(color: _amber),
                    ),
                  if (widget.item.usesDate)
                    TextButton.icon(
                      onPressed: () => _pick(true),
                      icon: const Icon(Icons.event),
                      label: Text(
                        _nextDate == null
                            ? 'Указать срок действия'
                            : 'До ${_serviceDate(_nextDate!)}',
                      ),
                    )
                  else if (widget.item.id != 'oil')
                    _number(
                      _next,
                      'Следующая замена на пробеге, км (необязательно)',
                      optional: true,
                    ),
                  _number(
                    _cost,
                    'Стоимость, ₸ (необязательно)',
                    optional: true,
                    money: true,
                  ),
                  TextFormField(
                    controller: _note,
                    maxLines: 3,
                    validator: (v) =>
                        widget.item.id.startsWith('other_') &&
                            (v ?? '').trim().isEmpty
                        ? 'Укажите название работы или документа'
                        : null,
                    style: const TextStyle(color: _paper),
                    decoration: const InputDecoration(
                      labelText: 'Что сделано',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: _saving ? null : _save,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _amber,
                      side: const BorderSide(color: _amber),
                      padding: const EdgeInsets.all(18),
                    ),
                    child: Text(
                      _saving ? 'Сохранение…' : 'Сохранить обслуживание',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ServiceNoteDialog extends StatefulWidget {
  final String initial;
  const _ServiceNoteDialog({required this.initial});
  @override
  State<_ServiceNoteDialog> createState() => _ServiceNoteDialogState();
}

class _ServiceNoteDialogState extends State<_ServiceNoteDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial,
  );
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xCE18313C), Color(0xE008141C)],
            ),
            border: Border.all(color: _amber.withValues(alpha: .65)),
            boxShadow: [
              BoxShadow(color: _amber.withValues(alpha: .12), blurRadius: 22),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      color: _amber,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Примечание',
                        style: TextStyle(
                          color: _paper,
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Закрыть',
                      icon: const Icon(Icons.close, color: _ice, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _text,
                  minLines: 3,
                  maxLines: 6,
                  style: const TextStyle(
                    color: _paper,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  cursorColor: _amber,
                  decoration: InputDecoration(
                    hintText: 'Детали, марка масла или важная заметка…',
                    hintStyle: TextStyle(
                      color: _ice.withValues(alpha: .65),
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: const Color(0x55040D12),
                    contentPadding: const EdgeInsets.all(16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: _ice.withValues(alpha: .3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: _amber),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, _text.text),
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('Сохранить'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _amber,
                    backgroundColor: const Color(0x33293739),
                    side: const BorderSide(color: _amber),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
}

/// Documents reuse existing IDs/storage so previously entered dates survive.
class _VehicleDocumentsPage extends StatefulWidget {
  final AppSession session;
  const _VehicleDocumentsPage({required this.session});
  @override
  State<_VehicleDocumentsPage> createState() => _VehicleDocumentsPageState();
}

class _VehicleDocumentsPageState extends State<_VehicleDocumentsPage> {
  late final repository = MaintenanceRepository(widget.session.login);
  MaintenanceBook? book;
  String? error;
  Timer? clock;
  @override
  void initState() {
    super.initState();
    load();
    clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    clock?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final value = await repository.load();
      if (mounted)
        setState(() {
          book = value;
          error = null;
        });
    } catch (_) {
      if (mounted)
        setState(
          () => error = 'Не удалось загрузить документы. Повторите попытку.',
        );
    }
  }

  int days(DateTime date) {
    final now = DateTime.now();
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  }

  String status(MaintenanceEntry? entry) {
    if (entry?.nextDate == null) return 'Укажите даты документа';
    final remaining = days(entry!.nextDate!);
    if (remaining < 0) return 'Истёк ${-remaining} дн. назад';
    if (remaining == 0) return 'Истекает сегодня';
    if (days(entry.date) > 0)
      return 'Начнёт действовать через ${days(entry.date)} дн. · до окончания $remaining дн.';
    return 'Осталось $remaining дн.';
  }

  Widget dates(MaintenanceEntry? entry) => Column(
    children: [
      dateLine('Дата заключения', entry?.date),
      const SizedBox(height: 10),
      dateLine('Дата завершения', entry?.nextDate),
    ],
  );
  Widget dateLine(String label, DateTime? date) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFFABB8C0), fontSize: 14),
        ),
      ),
      Text(
        date == null ? '—' : _serviceDate(date),
        style: const TextStyle(color: _paper, fontSize: 16),
      ),
    ],
  );
  Future<void> open(MaintenanceItem item) async {
    final entry = book!.latest(item.id);
    final update = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF11191D),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.title,
                style: const TextStyle(color: _paper, fontSize: 23),
              ),
              const SizedBox(height: 20),
              dates(entry),
              const SizedBox(height: 18),
              Text(
                status(entry),
                style: const TextStyle(color: _amber, fontSize: 18),
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.update),
                label: const Text('Обновить'),
              ),
            ],
          ),
        ),
      ),
    );
    if (update != true || !mounted) return;
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VehicleDocumentDatesDialog(
        item: item,
        entry: entry,
        repository: repository,
      ),
    );
    if (mounted) await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B1115),
    body: Stack(
      children: [
        _CinematicMore.backdrop(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: _amber),
                    ),
                    const Expanded(
                      child: Text(
                        'Документы',
                        style: TextStyle(
                          color: _paper,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: load,
                      tooltip: 'Обновить данные',
                      icon: const Icon(Icons.refresh, color: _amber),
                    ),
                  ],
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Color(0xFFD59C89)),
                    ),
                  ),
                Expanded(
                  child: book == null
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          children: [
                            for (final id in ['insurance', 'inspection'])
                              card(MaintenanceCatalog.byId(id)),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  Widget card(MaintenanceItem item) {
    final entry = book!.latest(item.id);
    final urgent = entry?.nextDate != null && days(entry!.nextDate!) <= 30;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: _CinematicMore.panel(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () => open(item),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      item.id == 'insurance'
                          ? Icons.shield_outlined
                          : Icons.fact_check_outlined,
                      color: _amber,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: _paper,
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: _amber),
                  ],
                ),
                const SizedBox(height: 22),
                dates(entry),
                const SizedBox(height: 20),
                Text(
                  status(entry),
                  style: TextStyle(
                    color: urgent ? const Color(0xFFD59C89) : _amber,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleDocumentDatesDialog extends StatefulWidget {
  final MaintenanceItem item;
  final MaintenanceEntry? entry;
  final MaintenanceRepository repository;
  const _VehicleDocumentDatesDialog({
    required this.item,
    required this.entry,
    required this.repository,
  });
  @override
  State<_VehicleDocumentDatesDialog> createState() =>
      _VehicleDocumentDatesDialogState();
}

class _VehicleDocumentDatesDialogState
    extends State<_VehicleDocumentDatesDialog> {
  late DateTime start =
      widget.entry?.date ?? DateUtils.dateOnly(DateTime.now());
  DateTime? end;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    end = widget.entry?.nextDate;
  }

  Future<void> pick(bool closing) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: closing
          ? (end ?? DateTime(start.year + 1, start.month, start.day))
          : start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted)
      setState(() {
        if (closing) {
          end = selected;
        } else {
          start = selected;
        }
        error = null;
      });
  }

  Future<void> save() async {
    if (saving) return;
    if (end == null || !end!.isAfter(start)) {
      setState(
        () => error = 'Дата завершения должна быть позже даты заключения.',
      );
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final book = await widget.repository.load();
      await widget.repository.record(
        itemId: widget.item.id,
        entryId: widget.entry?.id,
        date: start,
        nextDate: end,
        atKm: widget.entry?.odometer ?? book.odometer,
        currentKm: math.max(book.odometer, widget.entry?.odometer ?? 0),
        cost: widget.entry?.cost,
        note: widget.entry?.note ?? '',
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        setState(() {
          saving = false;
          error = 'Даты не сохранены. Повторите попытку.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      backgroundColor: const Color(0xFF11191D),
      title: Text(widget.item.title, style: const TextStyle(color: _paper)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: saving ? null : () => pick(false),
            icon: const Icon(Icons.calendar_month),
            label: Text('Заключён: ${_serviceDate(start)}'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: saving ? null : () => pick(true),
            icon: const Icon(Icons.event),
            label: Text(
              end == null
                  ? 'Дата завершения'
                  : 'Завершение: ${_serviceDate(end!)}',
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                error!,
                style: const TextStyle(color: Color(0xFFD59C89)),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: saving ? null : save,
          child: Text(saving ? 'Сохранение…' : 'Сохранить'),
        ),
      ],
    ),
  );
}

// Print-oriented A4 pages. Text is measured and split before rasterization;
// even a note longer than one page is kept in full.
class _MaintenanceBlankPreview extends StatefulWidget {
  final List<MaintenanceEntry> entries;
  final DateTimeRange period;
  final String name;
  const _MaintenanceBlankPreview({
    required this.entries,
    required this.period,
    required this.name,
  });
  @override
  State<_MaintenanceBlankPreview> createState() =>
      _MaintenanceBlankPreviewState();
}

class _MaintenanceBlankPreviewState extends State<_MaintenanceBlankPreview> {
  static const _channel = MethodChannel('melnitsa/advance_image');
  final List<dynamic> _pages = [];
  int _page = 0;
  bool _loading = true, _saving = false;
  String? _error;
  static const _widths = [48.0, 148.0, 172.0, 260.0, 492.0];

  TextPainter _text(String value, {double size = 21, bool bold = false}) =>
      TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Roboto',
            fontSize: size,
            height: 1.2,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

  List<String> _wrap(String value, double width) {
    final lines = <String>[];
    for (final paragraph in value.replaceAll('\r', '').split('\n')) {
      var line = '';
      // Runes avoid breaking a UTF-16 surrogate pair in a saved description.
      for (final rune in paragraph.runes) {
        final candidate = '$line${String.fromCharCode(rune)}';
        final measured = _text(candidate)..layout();
        final tooWide = measured.width > width;
        measured.dispose();
        if (tooWide && line.isNotEmpty) {
          lines.add(line);
          line = String.fromCharCode(rune);
        } else {
          line = candidate;
        }
      }
      lines.add(line);
    }
    return lines;
  }

  @override
  void initState() {
    super.initState();
    _render();
  }

  Future<void> _render() async {
    setState(() {
      _loading = true;
      _error = null;
      _pages.clear();
      _page = 0;
    });
    try {
      // Each segment: row number, wrapped cells, first line, line count.
      final layouts =
          <List<({List<List<String>> cells, int offset, int count})>>[[]];
      var used = 0;
      const capacity = 44;
      for (var i = 0; i < widget.entries.length; i++) {
        final entry = widget.entries[i];
        final item = MaintenanceCatalog.byId(entry.itemId);
        final values = [
          '${i + 1}',
          _serviceDate(entry.date),
          _serviceKm(entry.odometer),
          item.id.startsWith('other_')
              ? 'Другая работа · ${item.category}'
              : item.title,
          entry.note.trim().isEmpty ? '—' : entry.note,
        ];
        final cells = [
          for (var c = 0; c < values.length; c++)
            _wrap(values[c], _widths[c] - 16),
        ];
        final length = cells.map((c) => c.length).reduce(math.max);
        var offset = 0;
        while (offset < length) {
          if (used >= capacity) {
            layouts.add([]);
            used = 0;
          }
          // One extra line of space accounts for cell padding and border.
          final count = math.min(length - offset, capacity - used - 1);
          if (count <= 0) {
            layouts.add([]);
            used = 0;
            continue;
          }
          layouts.last.add((cells: cells, offset: offset, count: count));
          used += count + 1;
          offset += count;
        }
      }
      for (var page = 0; page < layouts.length; page++) {
        if (!mounted) return;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 1240, 1754),
          Paint()..color = Colors.white,
        );
        void draw(
          String value,
          double x,
          double y, {
          double size = 21,
          bool bold = false,
          double width = 1120,
        }) {
          final p = _text(value, size: size, bold: bold)
            ..layout(maxWidth: width);
          p.paint(canvas, Offset(x, y));
          p.dispose();
        }

        draw('МЕЛЬНИЦА', 60, 48, size: 24, bold: true);
        draw('ОТЧЁТ ПО ТО И ОБСЛУЖИВАНИЮ', 60, 98, size: 32, bold: true);
        draw(
          'Период: ${_serviceDate(widget.period.start)} — ${_serviceDate(widget.period.end)}',
          60,
          155,
          size: 23,
        );
        // A single-line employee name is scaled to fit the document header.
        final name = _text('Сотрудник: ${widget.name}', size: 22)..layout();
        final nameScale = math.min(1.0, 1120 / math.max(1.0, name.width));
        canvas.save();
        canvas.translate(60, 195);
        canvas.scale(nameScale);
        name.paint(canvas, Offset.zero);
        canvas.restore();
        name.dispose();
        var y = 248.0;
        final border = Paint()
          ..color = const Color(0xFF454545)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        final titles = ['№', 'Дата', 'Пробег', 'Вид работы', 'Что сделано'];
        var x = 60.0;
        for (var c = 0; c < titles.length; c++) {
          final rect = Rect.fromLTWH(x, y, _widths[c], 48);
          canvas.drawRect(rect, Paint()..color = const Color(0xFFF0F0F0));
          canvas.drawRect(rect, border);
          draw(
            titles[c],
            x + 8,
            y + 10,
            size: 20,
            bold: true,
            width: _widths[c] - 16,
          );
          x += _widths[c];
        }
        y += 48;
        for (final row in layouts[page]) {
          final height = (row.count + 1) * 27.0;
          x = 60;
          for (var c = 0; c < row.cells.length; c++) {
            canvas.drawRect(Rect.fromLTWH(x, y, _widths[c], height), border);
            final lines = row.cells[c]
                .skip(row.offset)
                .take(row.count)
                .toList();
            for (var l = 0; l < lines.length; l++) {
              draw(lines[l], x + 8, y + 10 + l * 27, width: _widths[c] - 16);
            }
            x += _widths[c];
          }
          y += height;
        }
        if (page == layouts.length - 1) {
          draw(
            'Всего работ за период: ${widget.entries.length}',
            60,
            y + 26,
            size: 23,
            bold: true,
          );
        } else {
          draw('Продолжение на следующем листе', 60, y + 26, size: 20);
        }
        draw(
          'Лист ${page + 1} из ${layouts.length}',
          990,
          1655,
          size: 20,
          width: 190,
        );
        draw(
          'Сформировано ${_serviceDate(DateTime.now())}',
          60,
          1655,
          size: 20,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(1240, 1754);
        picture.dispose();
        final data = await image.toByteData(format: ImageByteFormat.png);
        image.dispose();
        if (data == null) throw StateError('PNG encoding failed');
        if (!mounted) return;
        _pages.add(data.buffer.asUint8List());
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Не удалось сформировать бланк.';
        });
    }
  }

  Future<void> _save() async {
    if (_saving || _loading || _pages.isEmpty) return;
    setState(() => _saving = true);
    try {
      final saved = await _channel.invokeMethod<bool>('save', {
        'bytes': _pages[_page],
        'kind': 'maintenance',
      });
      if (saved == true && mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Лист ${_page + 1} сохранён')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось сохранить лист. Повторите попытку.'),
          ),
        );
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
        title: const Text('Бланк обслуживания'),
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
                      child: TextButton(
                        onPressed: _render,
                        child: Text('$_error Повторить'),
                      ),
                    )
                  : InteractiveViewer(
                      key: ValueKey(_page),
                      minScale: 1,
                      maxScale: 6,
                      child: Center(
                        child: Image.memory(_pages[_page], fit: BoxFit.contain),
                      ),
                    ),
            ),
            if (!_loading && _error == null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _saving || _page == 0
                        ? null
                        : () => setState(() => _page--),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Лист ${_page + 1} из ${_pages.length}'),
                  IconButton(
                    onPressed: _saving || _page + 1 >= _pages.length
                        ? null
                        : () => setState(() => _page++),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_alt),
                label: Text(
                  _saving ? 'Сохранение…' : 'Сохранить этот лист как картинку',
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
