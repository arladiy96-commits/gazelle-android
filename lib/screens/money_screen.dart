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
  static const gold = Color(0xFFCEA15B), muted = Color(0xFF90999E);
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
    Set<int>? kaspiInvoices,
    bool? inputKaspi,
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
        kaspiInvoices: kaspiInvoices ?? _draft.kaspiInvoices,
        inputKaspi: inputKaspi ?? _draft.inputKaspi,
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
    final kaspi = Set<int>.of(_draft.kaspiInvoices);
    final index = _draft.editing ?? values.length;
    if (_draft.inputKaspi) {
      kaspi.add(index);
    } else {
      kaspi.remove(index);
    }
    if (_draft.editing == null) {
      values.add(amount);
    } else {
      values[_draft.editing!] = amount;
    }
    _update(
      invoices: values,
      kaspiInvoices: kaspi,
      inputKaspi: false,
      input: '',
      clearEditing: true,
    );
    return true;
  }

  void _edit(int index) {
    if (_draft.input.isNotEmpty && _draft.editing == null) {
      _notice('Сначала добавьте или очистите введённую сумму');
      return;
    }
    if (_draft.editing != null && _draft.editing != index && !_commitInput())
      return;
    _update(
      input: MoneyCount.editable(_draft.invoices[index]),
      editing: index,
      inputKaspi: _draft.kaspiInvoices.contains(index),
    );
  }

  void _delete(int index) {
    final values = List<int>.of(_draft.invoices)..removeAt(index);
    final edit = _draft.editing;
    _update(
      invoices: values,
      kaspiInvoices: {
        for (final i in _draft.kaspiInvoices)
          if (i != index) i > index ? i - 1 : i,
      },
      inputKaspi: edit == index ? false : null,
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
    HapticFeedback.lightImpact();
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
          backgroundColor: const Color(0xFF11181C),
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
    Color color = const Color(0xFFE9EAEB),
    FontWeight weight = FontWeight.w400,
  }) => Text(
    text,
    style: TextStyle(color: color, fontSize: size, fontWeight: weight),
  );
  Widget _amount(
    int value, {
    double size = 23,
    Color color = const Color(0xFFE9EAEB),
  }) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: _text(
      '${MoneyCount.format(value)} ₸',
      size: size,
      color: color,
      weight: FontWeight.w600,
    ),
  );
  Widget _button(
    String label,
    VoidCallback? action, {
    bool selected = false,
    bool compact = false,
  }) => TextButton(
    onPressed: _busy ? null : action,
    style: TextButton.styleFrom(
      foregroundColor: selected ? gold : muted,
      minimumSize: Size(44, compact ? 34 : 44),
      tapTargetSize: compact
          ? MaterialTapTargetSize.shrinkWrap
          : MaterialTapTargetSize.padded,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      backgroundColor: selected ? const Color(0x334F422C) : Colors.transparent,
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
    return _MoneyMoreSurface(
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
                      'По накладным · ${count.invoiceCount}',
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
            child: Divider(height: 1, color: Color(0xFF353A3D)),
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
            child: _MoneyMoreSurface(
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
                                'Накладная ${i + 1}${_shown.kaspiInvoices.contains(i) ? ' · Каспи' : ''}',
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
            child: _MoneyMoreSurface(
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
                          color: selected ? gold : const Color(0xFFE9EAEB),
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
                      color: selected ? gold : const Color(0xFFE9EAEB),
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
    return _MoneyMoreSurface(
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
                _button(
                  'Отмена',
                  () =>
                      _update(input: '', clearEditing: true, inputKaspi: false),
                ),
              if (!_cashMode)
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          _update(inputKaspi: !_draft.inputKaspi);
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: _draft.inputKaspi ? gold : muted,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 40),
                  ),
                  icon: Icon(
                    _draft.inputKaspi
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    size: 18,
                  ),
                  label: const Text('Каспи', style: TextStyle(fontSize: 11)),
                ),
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
                                  color: const Color(0xFF60523F),
                                  width: .6,
                                ),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF20282C),
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
        'share',
        {
          'date': '${_detailDate(count.date)} · ${_detailTime(count.date)}',
          'rows': [
            for (final nominal in MoneyCount.denominations)
              [
                MoneyCount.format(nominal * 100),
                '${count.counts[nominal] ?? 0}',
                MoneyCount.format(nominal * (count.counts[nominal] ?? 0) * 100),
              ],
          ],
          'cash': MoneyCount.format(count.counted),
          'invoices': MoneyCount.format(count.expected),
          'invoiceCount': '${count.invoiceCount}',
          'kaspi': MoneyCount.format(count.kaspi),
          'kaspiCount': '${count.kaspiInvoices.length}',
          'difference': _difference(count),
        },
      );
    } on MissingPluginException {
      await _shareError(
        'В установленной сборке не найден Android-модуль отправки. '
        'Проверьте замену MainActivity.kt и установку нового APK.',
      );
    } on PlatformException catch (e) {
      await _shareError(
        '${e.code}: ${e.message ?? "Ошибка Android"}'
        '${e.details == null ? "" : "\n${e.details}"}',
      );
    } catch (e) {
      await _shareError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareError(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: const Color(0xFF11181C),
        title: const Text('Не удалось отправить покупюрник'),
        content: SingleChildScrollView(child: SelectableText(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
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
                child: _MoneyMoreSurface(
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
                        '${count.invoiceCount} накладных · ${_difference(count)}${count.kaspiInvoices.isEmpty ? '' : ' · Каспи: ${count.kaspiInvoices.length}'}',
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
  Future<void> _createReferenceSlip() async {
    final id = _draft.id;
    await _save();
    if (!mounted ||
        _history.isEmpty ||
        _history.first.id != id ||
        _draft.id == id)
      return;
    setState(() => _opened = _history.first);
    await _shareCount();
  }

  Widget _referenceMoney() => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back();
    },
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF080F13),
        body: LayoutBuilder(
          builder: (context, box) {
            final height = box.maxHeight * 864 / box.maxWidth;
            Widget at(double x, double y, double w, double h, Widget child) =>
                Positioned(
                  left: x,
                  top: y / 1536 * height,
                  width: w,
                  height: h / 1536 * height,
                  child: child,
                );
            Widget text(
              String v,
              double size, {
              Color color = const Color(0xFFEAEDEF),
              bool bold = false,
            }) => Text(
              v,
              style: TextStyle(
                fontSize: size,
                height: 1.15,
                color: color,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              ),
            );
            Widget fit(
              String v,
              double size, {
              Color color = const Color(0xFFEAEDEF),
            }) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: text(v, size, color: color, bold: true),
            );
            Widget tap(Widget child, VoidCallback? fn) => Material(
              color: Colors.transparent,
              child: InkWell(onTap: _busy ? null : fn, child: child),
            );
            String amount(int cents) => '${MoneyCount.format(cents)} ₸';
            BoxDecoration panel(bool selected) => BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFFE6B46B)
                    : const Color(0xFF55534A),
                width: selected ? 2 : 1,
              ),
              gradient: LinearGradient(
                colors: selected
                    ? const [Color(0xE042301B), Color(0xF0081218)]
                    : const [Color(0xEE182026), Color(0xF0071015)],
              ),
            );
            Widget sum(String title, int value) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                text(title, 22, color: muted),
                const SizedBox(height: 16),
                fit(amount(value), 34),
              ],
            );
            return SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: 864,
                  height: height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/scenes/money_reference.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                      at(
                        61,
                        49,
                        79,
                        76,
                        tap(
                          const Icon(
                            Icons.arrow_back,
                            color: Color(0xFFE6B46B),
                            size: 42,
                          ),
                          _back,
                        ),
                      ),
                      at(
                        177,
                        58,
                        490,
                        66,
                        Align(
                          alignment: Alignment.centerLeft,
                          child: text('Деньги', 50, bold: true),
                        ),
                      ),
                      at(
                        741,
                        51,
                        70,
                        72,
                        tap(
                          const Icon(
                            Icons.history,
                            color: Color(0xFFE6B46B),
                            size: 40,
                          ),
                          () => setState(() => _historyMode = true),
                        ),
                      ),
                      at(
                        104,
                        179,
                        214,
                        99,
                        sum(
                          'По накладным · ${_shown.invoiceCount}',
                          _shown.expected,
                        ),
                      ),
                      at(350, 179, 215, 99, sum('Насчитано', _shown.counted)),
                      at(
                        598,
                        179,
                        190,
                        106,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            text('Разница', 22, color: muted),
                            const SizedBox(height: 10),
                            fit(
                              amount(_shown.difference),
                              32,
                              color: _differenceColor(_shown),
                            ),
                            text(
                              _shown.invoiceCount == 0
                                  ? 'Нет накладных'
                                  : _shown.difference == 0
                                  ? '✓ Сходится'
                                  : _shown.difference < 0
                                  ? 'Не хватает'
                                  : 'Лишние',
                              21,
                              color: _differenceColor(_shown),
                            ),
                          ],
                        ),
                      ),
                      at(
                        78,
                        316,
                        320,
                        54,
                        tap(
                          Center(
                            child: text(
                              '▤  Накладные',
                              25,
                              color: !_cashMode ? gold : muted,
                            ),
                          ),
                          () => _tab(false),
                        ),
                      ),
                      at(
                        438,
                        316,
                        358,
                        54,
                        tap(
                          Center(
                            child: text(
                              'Подсчёт денег',
                              25,
                              color: _cashMode ? gold : muted,
                            ),
                          ),
                          () => _tab(true),
                        ),
                      ),
                      at(
                        70,
                        400,
                        298,
                        42,
                        Row(
                          children: [
                            Expanded(child: text('Список накладных', 21)),
                            SizedBox(
                              width: 46,
                              child: tap(
                                const Icon(
                                  Icons.add,
                                  color: Color(0xFFE6B46B),
                                  size: 34,
                                ),
                                () {
                                  _tab(false);
                                  if (_draft.editing != null) _commitInput();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      at(
                        407,
                        400,
                        400,
                        42,
                        Row(
                          children: [
                            Expanded(child: text('Подсчёт денег', 21)),
                            tap(text('Очистить', 19, color: muted), () async {
                              if (await _testConfirm(
                                    context,
                                    'Обнулить количество всех купюр и монет?',
                                  ) &&
                                  mounted) {
                                _update(counts: {});
                                setState(() => _cashInput = '');
                              }
                            }),
                          ],
                        ),
                      ),
                      at(
                        65,
                        453,
                        302,
                        405,
                        ColoredBox(
                          color: const Color(0xFF091115),
                          child: _shown.invoices.isEmpty
                              ? Center(
                                  child: text(
                                    'Добавьте накладную\nс помощью клавиатуры',
                                    23,
                                    color: muted,
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: _shown.invoices.length,
                                  itemBuilder: (_, i) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: panel(_draft.editing == i),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: tap(
                                            Padding(
                                              padding: const EdgeInsets.all(15),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  text(
                                                    'Накладная ${i + 1}${_shown.kaspiInvoices.contains(i) ? ' · Kaspi' : ''}',
                                                    19,
                                                    color: muted,
                                                  ),
                                                  const SizedBox(height: 7),
                                                  fit(
                                                    amount(_shown.invoices[i]),
                                                    25,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            () {
                                              _tab(false);
                                              _edit(i);
                                            },
                                          ),
                                        ),
                                        SizedBox(
                                          width: 36,
                                          height: 64,
                                          child: tap(
                                            const Icon(
                                              Icons.close,
                                              color: Color(0xFF90999E),
                                              size: 24,
                                            ),
                                            () => _delete(i),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      at(
                        88,
                        899,
                        260,
                        63,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            text('Итого по накладным', 20, color: muted),
                            const SizedBox(height: 7),
                            fit(amount(_shown.expected), 32, color: gold),
                          ],
                        ),
                      ),
                      at(
                        398,
                        453,
                        414,
                        493,
                        ListView.builder(
                          controller: _list,
                          padding: EdgeInsets.zero,
                          itemCount: MoneyCount.denominations.length,
                          itemBuilder: (_, i) {
                            final value = MoneyCount.denominations[i];
                            final count = _shown.counts[value] ?? 0;
                            return Container(
                              height: 68,
                              margin: const EdgeInsets.only(bottom: 5),
                              decoration: panel(
                                _cashMode && value == _denomination,
                              ),
                              child: tap(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 86,
                                        child: value >= 200
                                            ? Image.asset(
                                                'assets/images/scenes/money_kzt_$value.${value == 1000 ? 'png' : 'jpg'}',
                                                fit: BoxFit.contain,
                                              )
                                            : const Icon(
                                                Icons.toll_outlined,
                                                color: Color(0xFFE6B46B),
                                                size: 30,
                                              ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: fit(amount(value * 100), 22),
                                      ),
                                      Container(
                                        width: 59,
                                        height: 48,
                                        alignment: Alignment.center,
                                        decoration: panel(
                                          _cashMode && value == _denomination,
                                        ),
                                        child: text(
                                          '$count',
                                          26,
                                          color:
                                              _cashMode &&
                                                  value == _denomination
                                              ? gold
                                              : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: fit(
                                          amount(value * count * 100),
                                          22,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                () {
                                  _tab(true);
                                  if (_cashMode) _selectDenomination(value);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      at(
                        417,
                        957,
                        383,
                        50,
                        Row(
                          children: [
                            Expanded(
                              child: text('Итого насчитано', 21, color: muted),
                            ),
                            Expanded(
                              child: fit(
                                amount(_shown.counted),
                                32,
                                color: gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      at(
                        99,
                        1048,
                        678,
                        51,
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  text(
                                    _cashMode
                                        ? 'Количество купюр (${amount(_denomination * 100)})'
                                        : _draft.editing == null
                                        ? 'Сумма новой накладной'
                                        : 'Исправление накладной ${_draft.editing! + 1}',
                                    18,
                                    color: muted,
                                  ),
                                  if (_writeError.isNotEmpty)
                                    tap(
                                      text(
                                        _writeError,
                                        16,
                                        color: Colors.redAccent,
                                      ),
                                      _flush,
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 190,
                              child: fit(
                                _cashMode
                                    ? '${_draft.counts[_denomination] ?? 0} шт.'
                                    : '${_draft.input.isEmpty ? '0' : _draft.input} ₸',
                                30,
                                color: gold,
                              ),
                            ),
                            tap(
                              const Icon(
                                Icons.backspace_outlined,
                                color: Color(0xFFE6B46B),
                                size: 28,
                              ),
                              () => _key('C'),
                            ),
                          ],
                        ),
                      ),
                      for (var r = 0; r < 4; r++)
                        for (var c = 0; c < 3; c++)
                          at(
                            95 + c * 229,
                            1108 + r * 65,
                            217,
                            56,
                            tap(
                              Center(
                                child: text(
                                  r < 3
                                      ? '${r * 3 + c + 1}'
                                      : c == 0
                                      ? (_cashMode ? '00' : ',')
                                      : c == 1
                                      ? '0'
                                      : '⌫',
                                  34,
                                ),
                              ),
                              () => _key(
                                r < 3
                                    ? '${r * 3 + c + 1}'
                                    : c == 0
                                    ? (_cashMode ? '00' : ',')
                                    : c == 1
                                    ? '0'
                                    : '⌫',
                              ),
                            ),
                          ),
                      at(
                        88,
                        1373,
                        336,
                        66,
                        tap(
                          Center(
                            child: text(
                              _cashMode
                                  ? '→ Следующий номинал'
                                  : _draft.editing == null
                                  ? '+ Добавить накладную'
                                  : '✓ Сохранить изменение',
                              23,
                              color: gold,
                            ),
                          ),
                          _cashMode
                              ? _nextDenomination
                              : () {
                                  _commitInput();
                                },
                        ),
                      ),
                      at(
                        447,
                        1373,
                        335,
                        66,
                        tap(
                          Center(
                            child: text('Создать покупюрник', 23, color: gold),
                          ),
                          _createReferenceSlip,
                        ),
                      ),
                      if (!_cashMode)
                        at(
                          90,
                          1459,
                          350,
                          38,
                          tap(
                            Row(
                              children: [
                                Icon(
                                  _draft.inputKaspi
                                      ? Icons.check_box_outlined
                                      : Icons.check_box_outline_blank,
                                  color: gold,
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                text('Kaspi', 22, color: gold),
                                if (_draft.editing != null)
                                  Expanded(
                                    child: tap(
                                      Center(
                                        child: text('Отмена', 21, color: muted),
                                      ),
                                      () => _update(
                                        input: '',
                                        clearEditing: true,
                                        inputKaspi: false,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            () {
                              HapticFeedback.lightImpact();
                              _update(inputKaspi: !_draft.inputKaspi);
                            },
                          ),
                        ),
                      at(
                        650,
                        1459,
                        150,
                        38,
                        tap(
                          Center(child: text('Новый', 21, color: muted)),
                          _newCount,
                        ),
                      ),
                      if (_busy)
                        at(
                          89,
                          1500,
                          690,
                          4,
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

  @override
  Widget build(BuildContext context) =>
      !_loading && _loadError.isEmpty && !_historyMode && !_readOnly
      ? _referenceMoney()
      : PopScope(
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
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: gold,
                                    ),
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
                                          : () => setState(
                                              () => _historyMode = true,
                                            ),
                                      icon: const Icon(
                                        Icons.history,
                                        color: gold,
                                      ),
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
                                      child: CircularProgressIndicator(
                                        color: gold,
                                      ),
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
                                                  _button(
                                                    'Поделиться покупюрником',
                                                    _busy ? null : _shareCount,
                                                  ),
                                                if (_writeError.isNotEmpty)
                                                  InkWell(
                                                    onTap: () {
                                                      _flush().catchError(
                                                        (Object _) {},
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
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
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: _button(
                                                        'Подсчёт денег',
                                                        () => _tab(true),
                                                        selected: _cashMode,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Expanded(
                                                  child: _MoneyMoreSurface(
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

class _MoneyMoreSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _MoneyMoreSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
  });
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: _CinematicMore.panel(),
    child: Padding(padding: padding, child: child),
  );
}
