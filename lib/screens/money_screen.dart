part of 'app_shell.dart';

// Offline banknote images: National Bank of Kazakhstan, checked 2026-10-06.
// 20000 KZT: https://nationalbank.kz/ru/news/banknoty/6780
// 10000 KZT: https://nationalbank.kz/ru/news/banknoty/6781
// 5000 KZT: https://nationalbank.kz/ru/news/banknoty/6782
// 2000 KZT: https://nationalbank.kz/ru/news/banknoty/6784
// 1000 KZT: https://nationalbank.kz/ru/news/banknoty/6783
// 500 KZT: https://nationalbank.kz/ru/news/banknoty/6785
// 200 KZT: https://nationalbank.kz/ru/news/banknoty/6786

class MoneyScreen extends StatefulWidget {
  final AppSession session;
  final ValueChanged<int> onNavigate;
  const MoneyScreen({required this.session, required this.onNavigate});
  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> with WidgetsBindingObserver {
  static const gold = Color(0xFFCEA15B), muted = Color(0xFFB1B4B4);
  late final MoneyRepository _repository;
  MoneyCount _draft = MoneyCount.empty();
  List<MoneyCount> _history = [];
  MoneyCount? _opened;
  bool _loading = true, _busy = false, _historyMode = false;
  bool _cashMode = false,
      _replaceCash = true,
      _allowPop = false,
      _saved = false;
  int _denomination = 20000;
  String _cashInput = '', _loadError = '', _writeError = '';
  Timer? _debounce;
  final _list = ScrollController();
  MoneyCount get _shown => _opened ?? _draft;
  bool get _readOnly => _opened != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repository = MoneyRepository(
      '${widget.session.role.storageValue}:${widget.session.login}',
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = '';
    });
    try {
      final ledger = await _repository.load();
      if (!mounted) return;
      setState(() {
        _draft = ledger.draft;
        _history = ledger.history;
      });
    } catch (_) {
      if (mounted)
        setState(
          () => _loadError =
              'Не удалось открыть подсчёты. Ваши данные не перезаписаны.',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        !_loading &&
        !_busy &&
        _loadError.isEmpty) {
      _flush().catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _list.dispose();
    super.dispose();
  }

  Future<void> _flush() async {
    _debounce?.cancel();
    try {
      await _repository.store(_draft.snapshot(), List.of(_history));
      if (mounted && _writeError.isNotEmpty) setState(() => _writeError = '');
    } catch (_) {
      if (mounted)
        setState(() => _writeError = 'Не сохранено. Нажмите, чтобы повторить.');
      rethrow;
    }
  }

  void _change(MoneyCount value) {
    setState(() {
      _draft = value;
      _saved = false;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _flush().catchError((Object _) {});
    });
  }

  void _update({
    List<int>? invoices,
    Map<int, int>? counts,
    String? input,
    int? editing,
    bool clearEditing = false,
  }) {
    _change(
      MoneyCount(
        id: _draft.id,
        date: _draft.date,
        invoices: invoices ?? _draft.invoices,
        counts: counts ?? _draft.counts,
        input: input ?? _draft.input,
        editing: clearEditing ? null : editing ?? _draft.editing,
      ),
    );
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  bool _commitInput() {
    if (_draft.input.isEmpty && _draft.editing == null) return true;
    final amount = MoneyCount.parseAmount(_draft.input);
    if (amount <= 0) {
      _notice('Введите сумму больше нуля');
      return false;
    }
    final values = List<int>.of(_draft.invoices);
    if (_draft.editing == null) {
      values.add(amount);
    } else {
      values[_draft.editing!] = amount;
    }
    _update(invoices: values, input: '', clearEditing: true);
    return true;
  }

  void _edit(int index) {
    if (_draft.input.isNotEmpty && _draft.editing == null) {
      _notice('Сначала добавьте или очистите введённую сумму');
      return;
    }
    if (_draft.editing != null && _draft.editing != index && !_commitInput())
      return;
    _update(input: MoneyCount.editable(_draft.invoices[index]), editing: index);
  }

  void _delete(int index) {
    final values = List<int>.of(_draft.invoices)..removeAt(index);
    final edit = _draft.editing;
    _update(
      invoices: values,
      input: edit == index ? '' : null,
      clearEditing: edit == index,
      editing: edit != null && edit > index ? edit - 1 : edit,
    );
  }

  void _selectDenomination(int value) {
    setState(() {
      _denomination = value;
      _cashInput = '${_draft.counts[value] ?? 0}';
      _replaceCash = true;
    });
  }

  void _key(String key) {
    if (_busy || _readOnly) return;
    if (_cashMode) {
      var value = _replaceCash && key != '⌫' ? '' : _cashInput;
      if (key == 'C') {
        value = '';
      } else if (key == '⌫') {
        value = value.isEmpty ? '' : value.substring(0, value.length - 1);
      } else if (key != ',') {
        value = value == '0' ? key : value + key;
      }
      if (value.length > 6) return;
      _cashInput = value;
      _replaceCash = false;
      _update(
        counts: {..._draft.counts, _denomination: int.tryParse(value) ?? 0},
      );
    } else {
      var value = _draft.input;
      if (key == 'C') {
        value = '';
      } else if (key == '⌫') {
        value = value.isEmpty ? '' : value.substring(0, value.length - 1);
      } else if (key == ',') {
        if (!value.contains(',')) value = '${value.isEmpty ? '0' : value},';
      } else {
        value = value == '0' ? key : value + key;
      }
      if (!RegExp(r'^\d{0,9}(,\d{0,2})?$').hasMatch(value)) return;
      _update(input: value);
    }
  }

  void _tab(bool cash) {
    if (!_readOnly && cash && !_cashMode && !_commitInput()) return;
    setState(() {
      _cashMode = cash;
      _replaceCash = true;
      _cashInput = '${_draft.counts[_denomination] ?? 0}';
    });
  }

  void _nextDenomination() {
    final values = MoneyCount.denominations;
    final index = values.indexOf(_denomination);
    if (index == values.length - 1) {
      _save();
      return;
    }
    _selectDenomination(values[index + 1]);
    if (_list.hasClients) {
      _list.animateTo(
        math.min((index + 1) * 68.0, _list.position.maxScrollExtent),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _save() async {
    if (_busy || !_commitInput()) return;
    if (_draft.invoices.isEmpty) {
      _notice('Добавьте хотя бы одну накладную');
      return;
    }
    _debounce?.cancel();
    setState(() => _busy = true);
    final record = _draft.snapshot(committed: true);
    final history = [record, ..._history.where((e) => e.id != record.id)];
    final nextDraft = MoneyCount.empty();
    try {
      // Archive and reset are persisted together, before clearing the screen.
      await _repository.store(nextDraft, history);
      if (!mounted) return;
      setState(() {
        _draft = nextDraft;
        _history = history;
        _saved = false;
        _cashMode = false;
        _historyMode = false;
        _opened = null;
        _denomination = 20000;
        _cashInput = '';
        _replaceCash = true;
        _writeError = '';
      });
      _notice('Подсчёт сохранён в истории');
    } catch (_) {
      if (mounted) {
        setState(() => _writeError = 'Не сохранено. Нажмите, чтобы повторить.');
        _notice('Не удалось сохранить. Попробуйте ещё раз.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _newCount() async {
    if (_draft.hasData && !_saved) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF161A1C),
          surfaceTintColor: Colors.transparent,
          title: const Text('Начать новый подсчёт?'),
          content: const Text(
            'Текущий черновик будет очищен. Чтобы оставить его в истории, сначала нажмите «Сохранить».',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Новый подсчёт'),
            ),
          ],
        ),
      );
      if (yes != true || !mounted) return;
    }
    _change(MoneyCount.empty());
    setState(() {
      _cashMode = false;
      _historyMode = false;
      _opened = null;
      _denomination = 20000;
      _cashInput = '';
    });
  }

  Future<void> _back() async {
    if (_busy) return;
    if (_opened != null) {
      setState(() {
        _opened = null;
        _historyMode = true;
      });
      return;
    }
    if (_historyMode) {
      setState(() => _historyMode = false);
      return;
    }
    setState(() => _busy = true);
    try {
      if (!_loading && _loadError.isEmpty) await _flush();
      if (!mounted) return;
      setState(() => _allowPop = true);
      // Let PopScope receive canPop before asking Navigator to pop.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop();
      });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _text(
    String text, {
    double size = 13,
    Color color = Colors.white,
    FontWeight weight = FontWeight.w400,
  }) => Text(
    text,
    style: TextStyle(color: color, fontSize: size, fontWeight: weight),
  );
  Widget _amount(int value, {double size = 23, Color color = Colors.white}) =>
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: _text(
          '${MoneyCount.format(value)} ₸',
          size: size,
          color: color,
          weight: FontWeight.w600,
        ),
      );
  Widget _button(String label, VoidCallback? action, {bool selected = false, bool compact = false}) =>
      TextButton(
        onPressed: _busy ? null : action,
        style: TextButton.styleFrom(
          foregroundColor: selected ? gold : muted,
          minimumSize: Size(44, compact ? 34 : 44),
          tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : MaterialTapTargetSize.padded,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: selected
              ? const Color(0x334F422C)
              : Colors.transparent,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: compact ? 11 : 12),
        ),
      );
  String _difference(MoneyCount count) => count.invoices.isEmpty
      ? 'Добавьте накладные для сверки'
      : count.difference == 0
      ? '✓ Сходится'
      : count.difference < 0
      ? 'Не хватает −${MoneyCount.format(-count.difference)} ₸'
      : 'Лишние +${MoneyCount.format(count.difference)} ₸';
  Color _differenceColor(MoneyCount count) => count.invoices.isEmpty
      ? muted
      : count.difference == 0
      ? const Color(0xFF95BBA5)
      : count.difference < 0
      ? const Color(0xFFD29280)
      : gold;
  Widget _totals() {
    final count = _shown;
    return _GasMetalSurface(
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _text(
                      'По накладным · ${count.invoices.length}',
                      size: 11,
                      color: muted,
                    ),
                    const SizedBox(height: 3),
                    _amount(count.expected),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _text('Насчитано', size: 11, color: muted),
                    const SizedBox(height: 3),
                    _amount(count.counted),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Divider(height: 1, color: Color(0xFF49453A)),
          ),
          Row(
            children: [
              _text('Разница  ', size: 11, color: muted),
              Expanded(
                child: _text(
                  _difference(count),
                  size: 13,
                  color: _differenceColor(count),
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _invoices() => _shown.invoices.isEmpty
      ? Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _text(
              'Введите сумму накладной внизу\nи нажмите «Добавить».',
              color: muted,
            ),
          ),
        )
      : ListView.builder(
          key: const ValueKey('invoices'),
          controller: _list,
          padding: const EdgeInsets.all(7),
          itemCount: _shown.invoices.length,
          itemBuilder: (c, i) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: _GasMetalSurface(
              compact: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _readOnly || _busy ? null : () => _edit(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            _text('${i + 1}'.padLeft(2, '0'), color: gold),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _text(
                                'Накладная ${i + 1}',
                                size: 11,
                                color: muted,
                              ),
                            ),
                            Flexible(
                              child: _amount(_shown.invoices[i], size: 18),
                            ),
                            if (!_readOnly)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 15,
                                  color: muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!_readOnly)
                    IconButton(
                      tooltip: 'Удалить накладную ${i + 1}',
                      onPressed: _busy ? null : () => _delete(i),
                      icon: const Icon(Icons.close, size: 19, color: muted),
                    ),
                ],
              ),
            ),
          ),
        );
  Widget _cash() => ListView.builder(
    key: const ValueKey('cash'),
    controller: _list,
    padding: const EdgeInsets.all(7),
    itemCount: MoneyCount.denominations.length,
    itemBuilder: (context, index) {
      final value = MoneyCount.denominations[index],
          quantity = _shown.counts[MoneyCount.denominations[index]] ?? 0;
      final selected = !_readOnly && value == _denomination;
      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Semantics(
          button: !_readOnly,
          selected: selected,
          label: '$value тенге, количество $quantity',
          child: InkWell(
            onTap: _readOnly || _busy ? null : () => _selectDenomination(value),
            child: _GasMetalSurface(
              compact: true,
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 67,
                    height: 43,
                    child: value >= 200
                        ? Image.asset(
                            'assets/images/scenes/money_kzt_$value.${value == 1000 ? 'png' : 'jpg'}',
                            fit: BoxFit.contain,
                            errorBuilder: (_, error, stack) => const Icon(
                              Icons.payments_outlined,
                              color: muted,
                            ),
                          )
                        : const Icon(
                            Icons.toll_outlined,
                            size: 26,
                            color: muted,
                          ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _text(
                          '${MoneyCount.format(value * 100)} ₸',
                          size: 14,
                          color: selected ? gold : Colors.white,
                        ),
                        _text(
                          value == 200
                              ? 'купюры / монеты'
                              : value < 200
                              ? 'монеты'
                              : 'купюры',
                          size: 9,
                          color: muted,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0x90101517),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selected ? gold : const Color(0xFF51524E),
                        width: selected ? 1.2 : .5,
                      ),
                    ),
                    child: _text(
                      '$quantity',
                      size: 17,
                      color: selected ? gold : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 82,
                    child: _amount(value * quantity * 100, size: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  Widget _keyboard(bool short) {
    final editing = _draft.editing;
    return _GasMetalSurface(
      padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _text(
                      _cashMode
                          ? '${MoneyCount.format(_denomination * 100)} ₸ · количество'
                          : editing == null
                          ? 'Сумма новой накладной'
                          : 'Исправление накладной ${editing + 1}',
                      size: 10,
                      color: muted,
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _text(
                        _cashMode
                            ? '${_draft.counts[_denomination] ?? 0} шт.'
                            : '${_draft.input.isEmpty ? '0' : _draft.input} ₸',
                        size: 21,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_cashMode && editing != null)
                _button('Отмена', () => _update(input: '', clearEditing: true)),
              _button('Очистить', () => _key('C')),
            ],
          ),
          const SizedBox(height: 4),
          for (final keys in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            [_cashMode ? '00' : ',', '0', '⌫'],
          ])
            Row(
              children: [
                for (final key in keys)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: SizedBox(
                        height: short ? 39 : 43,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(7),
                            onTap: _busy ? null : () => _key(key),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: const Color(0xFF565147),
                                  width: .6,
                                ),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF2B2E2D),
                                    Color(0xFF131819),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: _text(
                                  key,
                                  size: 21,
                                  color: key == '⌫'
                                      ? gold
                                      : const Color(0xFFE8E6DE),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: _button(
                  _cashMode
                      ? 'Следующий номинал →'
                      : editing == null
                      ? '+ Добавить'
                      : 'Применить',
                  _cashMode
                      ? _nextDenomination
                      : () {
                          if (_commitInput() && _list.hasClients) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && _list.hasClients)
                                _list.jumpTo(_list.position.maxScrollExtent);
                            });
                          }
                        },
                  selected: true,
                ),
              ),
              if (_cashMode)
                _button(
                  _saved ? '✓ Сохранено' : 'Сохранить',
                  _saved ? null : _save,
                  selected: true,
                )
              else
                _button('К наличным →', () => _tab(true)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareCount() async {
    final count = _opened;
    if (count == null || _busy) return;
    setState(() => _busy = true);
    try {
      await const MethodChannel('melnitsa/money_share').invokeMethod<void>(
        'share', {
          'date': '${_detailDate(count.date)} · ${_detailTime(count.date)}',
          'rows': [for (final nominal in MoneyCount.denominations)
            [MoneyCount.format(nominal * 100), '${count.counts[nominal] ?? 0}',
              MoneyCount.format(nominal * (count.counts[nominal] ?? 0) * 100)]],
          'cash': MoneyCount.format(count.counted),
          'invoices': MoneyCount.format(count.expected),
          'invoiceCount': '${count.invoices.length}',
          'difference': _difference(count),
        },
      );
    } on MissingPluginException {
      await _shareError('В установленной сборке не найден Android-модуль отправки. '
        'Проверьте замену MainActivity.kt и установку нового APK.');
    } on PlatformException catch (e) {
      await _shareError('${e.code}: ${e.message ?? "Ошибка Android"}'
        '${e.details == null ? "" : "\n${e.details}"}');
    } catch (e) {
      await _shareError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareError(String message) async {
    if (!mounted) return;
    await showDialog<void>(context: context, builder: (dialog) => AlertDialog(
      backgroundColor: const Color(0xFF161A1C),
      title: const Text('Не удалось отправить покупюрник'),
      content: SingleChildScrollView(child: SelectableText(message)),
      actions: [TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Закрыть'))],
    ));
  }

  Widget _historyList() => _history.isEmpty
      ? Center(child: _text('Сохранённых подсчётов пока нет', color: muted))
      : ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 7),
          itemCount: _history.length,
          itemBuilder: (c, i) {
            final count = _history[i], date = _history[i].date;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() {
                  _opened = count;
                  _historyMode = false;
                  _cashMode = false;
                }),
                child: _GasMetalSurface(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _text(
                              '${_detailDate(date)} · ${_detailTime(date)}',
                              color: muted,
                              size: 12,
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: gold),
                        ],
                      ),
                      _amount(count.expected),
                      const SizedBox(height: 5),
                      _text(
                        '${count.invoices.length} накладных · ${_difference(count)}',
                        size: 12,
                        color: _differenceColor(count),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back();
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
              child: LayoutBuilder(
                builder: (context, box) {
                  final short = box.maxHeight < 700;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 3, 12, 2),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Назад',
                              onPressed: _busy ? null : _back,
                              icon: const Icon(Icons.arrow_back, color: gold),
                            ),
                            Expanded(
                              child: _text(
                                _historyMode
                                    ? 'История подсчётов'
                                    : _readOnly
                                    ? 'Сохранённый подсчёт'
                                    : 'Деньги',
                                size: _historyMode || _readOnly ? 19 : 25,
                                weight: FontWeight.w600,
                              ),
                            ),
                            if (!_loading &&
                                _loadError.isEmpty &&
                                !_historyMode &&
                                !_readOnly)
                              IconButton(
                                tooltip: 'История подсчётов',
                                onPressed: _busy
                                    ? null
                                    : () => setState(() => _historyMode = true),
                                icon: const Icon(Icons.history, color: gold),
                              ),
                            if (!_loading &&
                                _loadError.isEmpty &&
                                !_readOnly &&
                                !_historyMode)
                              IconButton(
                                tooltip: 'Новый подсчёт',
                                onPressed: _busy ? null : _newCount,
                                icon: const Icon(Icons.add, color: gold),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _loading
                            ? const Center(
                                child: CircularProgressIndicator(color: gold),
                              )
                            : _loadError.isNotEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: _text(_loadError),
                                    ),
                                    _button('Повторить', _load),
                                  ],
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: _historyMode
                                    ? _historyList()
                                    : Column(
                                        children: [
                                          _totals(),
                                          if (_readOnly)
                                            _button('Поделиться покупюрником', _busy ? null : _shareCount),
                                          if (_writeError.isNotEmpty)
                                            InkWell(
                                              onTap: () {
                                                _flush().catchError(
                                                  (Object _) {},
                                                );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                child: _text(
                                                  _writeError,
                                                  size: 11,
                                                  color: const Color(
                                                    0xFFD29280,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _button(
                                                  'Накладные',
                                                  () => _tab(false),
                                                  selected: !_cashMode,
                                                  compact: true,
                                                ),
                                              ),
                                              Expanded(
                                                child: _button(
                                                  'Подсчёт денег',
                                                  () => _tab(true),
                                                  selected: _cashMode,
                                                  compact: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Expanded(
                                            child: _GasMetalSurface(
                                              child: _cashMode
                                                  ? _cash()
                                                  : _invoices(),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          if (!_readOnly)
                                            _keyboard(short)
                                          else
                                            _button(
                                              '← К истории подсчётов',
                                              () => _back(),
                                            ),
                                        ],
                                      ),
                              ),
                      ),
                      const SizedBox(height: 3),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
