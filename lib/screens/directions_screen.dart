part of 'app_shell.dart';

Future<String?> _pickDirection(BuildContext context, {String? type}) async {
  try {
    final names = await TestStore.directionNames(type);
    if (!context.mounted) return null;
    if (names.isEmpty) {
      await Navigator.push(
        context,
        _SceneRoute<void>(
          builder: (_) => _DirectionsScreen(initialType: type ?? 'Город'),
        ),
      );
      if (!context.mounted) return null;
      final updated = await TestStore.directionNames(type);
      if (!context.mounted || updated.isEmpty) return null;
      return _pickQuickValue(context, 'Направление', updated);
    }
    return _pickQuickValue(context, 'Направление', names);
  } catch (_) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось загрузить направления')),
      );
    return null;
  }
}

class _DirectionsScreen extends StatefulWidget {
  final String initialType;
  const _DirectionsScreen({this.initialType = 'Город'});
  @override
  State<_DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<_DirectionsScreen> {
  static const gold = Color(0xFFE6B665);
  late String _type = widget.initialType;
  TestState? _book;
  String? _error;
  int _request = 0;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    TestStore.revision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _request++;
    TestStore.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final book = await TestStore.load();
      if (mounted && request == _request)
        setState(() {
          _book = book;
          _error = null;
        });
    } catch (_) {
      if (mounted && request == _request)
        setState(() => _error = 'Не удалось загрузить направления');
    }
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    if (_busy) return;
    _busy = true;
    try {
      await showDialog<void>(
        context: context,
        builder: (_) => _DirectionNameDialog(type: _type, row: row),
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    if (_busy) return;
    _busy = true;
    try {
      final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF101A20),
          title: const Text('Удалить направление?'),
          content: Text(
            '«${row['name']}» исчезнет из выбора новых рейсов. Уже записанные рейсы и отчёты сохранятся.',
          ),
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
      if (yes == true) await TestStore.deleteDirection(row['id'] as String);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось удалить направление')),
        );
    } finally {
      _busy = false;
    }
  }

  BoxDecoration panel({bool active = false, double radius = 15}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: active ? gold : gold.withValues(alpha: .57),
          width: active ? 1.3 : .8,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? const [Color(0xFFB98235), Color(0xFF5F4629), Color(0xFF936A31)]
              : const [Color(0xF51A2227), Color(0xFC0C1318), Color(0xF01A1E20)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .65),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
          if (active)
            BoxShadow(color: gold.withValues(alpha: .15), blurRadius: 9),
        ],
      );
  @override
  Widget build(BuildContext context) {
    final rows =
        _book?.directions
            .where((e) => e['active'] != false && e['type'] == _type)
            .toList() ??
        <Map<String, dynamic>>[];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF081017),
        body: LayoutBuilder(
          builder: (context, box) {
            final scale = box.maxWidth / 432;
            final top = math.max(
              MediaQuery.paddingOf(context).top + 20,
              72 * scale,
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/scenes/directions_reference.png',
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    28 * scale,
                    top,
                    28 * scale,
                    math.max(16.0, MediaQuery.paddingOf(context).bottom),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44 * scale,
                            height: 44 * scale,
                            decoration: panel(radius: 50),
                            child: IconButton(
                              tooltip: 'Назад',
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.arrow_back,
                                color: gold,
                                size: 27 * scale,
                              ),
                            ),
                          ),
                          SizedBox(width: 16 * scale),
                          Expanded(
                            child: Text(
                              'Направления',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26 * scale,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 60 * scale,
                          top: 5 * scale,
                        ),
                        child: Text(
                          'Список городских и районных направлений',
                          style: TextStyle(
                            color: const Color(0xFFC1C6CA),
                            fontSize: 13 * scale,
                          ),
                        ),
                      ),
                      SizedBox(height: 28 * scale),
                      Container(
                        height: 52 * scale,
                        padding: EdgeInsets.all(3 * scale),
                        decoration: panel(radius: 17 * scale),
                        child: Row(
                          children: [
                            for (final type in ['Город', 'Район'])
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(
                                      14 * scale,
                                    ),
                                    onTap: () => setState(() => _type = type),
                                    child: Ink(
                                      decoration: _type == type
                                          ? panel(
                                              active: true,
                                              radius: 14 * scale,
                                            )
                                          : null,
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              type == 'Город'
                                                  ? Icons.location_city
                                                  : Icons.landscape_outlined,
                                              color: _type == type
                                                  ? gold
                                                  : const Color(0xFF82909A),
                                              size: 25 * scale,
                                            ),
                                            SizedBox(width: 10 * scale),
                                            Text(
                                              type,
                                              style: TextStyle(
                                                color: _type == type
                                                    ? Colors.white
                                                    : const Color(0xFF82909A),
                                                fontSize: 17 * scale,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14 * scale),
                      Row(
                        children: [
                          Icon(
                            _type == 'Город'
                                ? Icons.location_city
                                : Icons.landscape_outlined,
                            color: gold,
                            size: 27 * scale,
                          ),
                          SizedBox(width: 9 * scale),
                          Expanded(
                            child: Text(
                              _type == 'Город'
                                  ? 'ГОРОДСКИЕ НАПРАВЛЕНИЯ'
                                  : 'РАЙОННЫЕ НАПРАВЛЕНИЯ',
                              style: TextStyle(
                                color: const Color(0xFFC4CDD2),
                                fontSize: 10.5 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            decoration: panel(radius: 30),
                            child: TextButton.icon(
                              onPressed: _edit,
                              icon: Icon(
                                Icons.add,
                                color: gold,
                                size: 20 * scale,
                              ),
                              label: Text(
                                'Добавить',
                                style: TextStyle(
                                  color: gold,
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 11 * scale,
                                ),
                                minimumSize: Size(0, 34 * scale),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * scale),
                      Expanded(
                        child: _error != null
                            ? Center(
                                child: TextButton(
                                  onPressed: _load,
                                  child: Text(
                                    '$_error\nПовторить',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : _book == null
                            ? const Center(
                                child: CircularProgressIndicator(color: gold),
                              )
                            : rows.isEmpty
                            ? Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: panel(),
                                  child: Text(
                                    'Пока нет направлений.\nНажмите «Добавить».',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16 * scale,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                key: ValueKey(_type),
                                padding: EdgeInsets.only(bottom: 12 * scale),
                                itemCount: rows.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 5 * scale),
                                itemBuilder: (context, index) {
                                  final row = rows[index];
                                  return Container(
                                    decoration: panel(radius: 14 * scale),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          14 * scale,
                                        ),
                                        onTap: () => _edit(row),
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            13 * scale,
                                            7 * scale,
                                            4 * scale,
                                            7 * scale,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 38 * scale,
                                                height: 38 * scale,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        11 * scale,
                                                      ),
                                                  gradient:
                                                      const LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors: [
                                                          Color(0xFF453A29),
                                                          Color(0xFF181D20),
                                                        ],
                                                      ),
                                                  border: Border.all(
                                                    color: gold.withValues(
                                                      alpha: .15,
                                                    ),
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.location_on,
                                                  color: gold,
                                                  size: 25 * scale,
                                                ),
                                              ),
                                              SizedBox(width: 14 * scale),
                                              Expanded(
                                                child: Text(
                                                  row['name'] as String,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16 * scale,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                tooltip:
                                                    'Действия с направлением',
                                                color: const Color(0xFF152027),
                                                icon: const Icon(
                                                  Icons.more_vert,
                                                  color: Color(0xFFCCD0D4),
                                                ),
                                                onSelected: (value) {
                                                  if (value == 'edit') {
                                                    _edit(row);
                                                  } else {
                                                    _delete(row);
                                                  }
                                                },
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
                                              ),
                                            ],
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
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DirectionNameDialog extends StatefulWidget {
  final String type;
  final Map<String, dynamic>? row;
  const _DirectionNameDialog({required this.type, this.row});
  @override
  State<_DirectionNameDialog> createState() => _DirectionNameDialogState();
}

class _DirectionNameDialogState extends State<_DirectionNameDialog> {
  late final _name = TextEditingController(
    text: widget.row?['name'] as String? ?? '',
  );
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await TestStore.saveDirection(
        id: widget.row?['id'] as String?,
        type: widget.type,
        name: _name.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = _testError(e);
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      backgroundColor: const Color(0xFF101A20),
      title: Text(
        widget.row == null ? 'Добавить направление' : 'Изменить направление',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.type,
            style: const TextStyle(color: _DirectionsScreenState.gold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            autofocus: true,
            enabled: !_saving,
            maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Название',
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Сохранение…' : 'Сохранить'),
        ),
      ],
    ),
  );
}
