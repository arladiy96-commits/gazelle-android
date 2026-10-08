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
  String _query = '';
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
                    for (final item in MaintenanceCatalog.items)
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

  Widget _panel(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: _CinematicMore.panel(),
    child: child,
  );

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
    final rows =
        (book?.entries ?? <MaintenanceEntry>[]).where((e) {
          final item = MaintenanceCatalog.byId(e.itemId);
          return !e.example &&
              (_filter == null || e.itemId == _filter) &&
              '${item.title} ${e.note} ${_serviceDate(e.date)} ${e.odometer}'
                  .toLowerCase()
                  .contains(_query.toLowerCase());
        }).toList()..sort((a, b) {
          final d = b.date.compareTo(a.date);
          return d == 0 ? b.id.compareTo(a.id) : d;
        });
    return Scaffold(
      backgroundColor: const Color(0xFF0B1115),
      body: Stack(
        children: [
          _CinematicMore.backdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                          'ТО и обслуживание',
                          style: TextStyle(
                            color: _paper,
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _load,
                        tooltip: 'Обновить',
                        icon: const Icon(Icons.refresh, color: _amber),
                      ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFD59C89)),
                      ),
                    ),
                  if (book == null)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _panel(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.oil_barrel_outlined,
                                color: _amber,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Замена масла',
                                  style: TextStyle(color: _paper, fontSize: 18),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _record(MaintenanceCatalog.byId('oil')),
                                child: Text(
                                  oil == null ? 'Добавить' : 'Заменено',
                                ),
                              ),
                            ],
                          ),
                          Text(
                            remaining == null
                                ? 'Добавьте последнюю замену'
                                : remaining > 0
                                ? 'До замены ${_fmtInt((remaining).toDouble())} км'
                                : remaining == 0
                                ? 'Пора менять масло'
                                : 'Просрочено на ${_fmtInt((-remaining).toDouble())} км',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w600,
                              color: remaining != null && remaining <= 0
                                  ? const Color(0xFFD59C89)
                                  : _amber,
                            ),
                          ),
                          if (oil != null) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value:
                                  ((book.odometer - oil.odometer) / oilInterval)
                                      .clamp(0.0, 1.0),
                              color: _amber,
                              backgroundColor: const Color(0xFF303639),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_serviceDate(oil.date)} · ${_fmtInt((oil.odometer).toDouble())} км → ${_fmtInt((oil.odometer + oilInterval).toDouble())} км',
                              style: const TextStyle(
                                color: _paper,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            'Текущий пробег: ${_fmtInt((book.odometer).toDouble())} км · интервал ${_fmtInt(oilInterval.toDouble())} км',
                            style: const TextStyle(
                              color: Color(0xFFABB8C0),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(color: _paper),
                      decoration: const InputDecoration(
                        hintText: 'Найти работу, дату или пробег',
                        prefixIcon: Icon(Icons.search, color: _amber),
                        filled: true,
                        fillColor: Color(0xD010181D),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'История · ${rows.length}',
                            style: const TextStyle(color: _paper),
                          ),
                        ),
                        if (_filter != null)
                          TextButton(
                            onPressed: () => setState(() => _filter = null),
                            child: const Text('Все работы'),
                          ),
                      ],
                    ),
                    Expanded(
                      child: rows.isEmpty
                          ? const Center(
                              child: Text(
                                'Записей нет. Добавьте выполненную работу.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _paper),
                              ),
                            )
                          : ListView.separated(
                              itemCount: rows.length,
                              separatorBuilder: (_, i) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final entry = rows[i];
                                final item = MaintenanceCatalog.byId(
                                  entry.itemId,
                                );
                                return Container(
                                  decoration: _CinematicMore.panel(),
                                  child: ListTile(
                                    onTap: () => _record(item, entry: entry),
                                    title: Text(
                                      item.id.startsWith('other_')
                                          ? entry.note
                                          : item.title,
                                      style: const TextStyle(
                                        color: _paper,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${_serviceDate(entry.date)} · ${_fmtInt((entry.odometer).toDouble())} км${!item.id.startsWith('other_') && entry.note.isNotEmpty ? '\n${entry.note}' : ''}',
                                      style: const TextStyle(
                                        color: Color(0xFFABB8C0),
                                      ),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: _amber,
                                      ),
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Изменить'),
                                        ),
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
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xE0192125),
                          foregroundColor: _amber,
                          minimumSize: const Size(0, 52),
                          side: const BorderSide(color: Color(0xFF776044)),
                        ),
                        onPressed: _add,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить обслуживание'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
