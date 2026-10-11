part of 'app_shell.dart';

class LoadingInvoiceScreen extends StatefulWidget {
  final String owner;
  final InvoiceRecognitionService recognition;
  const LoadingInvoiceScreen({
    super.key,
    required this.owner,
    this.recognition = const _DefaultInvoiceRecognition(),
  });
  @override
  State<LoadingInvoiceScreen> createState() => _LoadingInvoiceScreenState();
}

// UI depends solely on the recognition contract; replace the constructor injection.
class _DefaultInvoiceRecognition implements InvoiceRecognitionService {
  const _DefaultInvoiceRecognition();
  @override
  Future<InvoiceRecognitionResult> recognize({
    required String invoiceId,
    required List<String> photoPaths,
  }) => MockInvoiceRecognitionService().recognize(
    invoiceId: invoiceId,
    photoPaths: photoPaths,
  );
}

class _LoadingInvoiceScreenState extends State<LoadingInvoiceScreen> {
  static const gold = Color(0xFFE6B46B),
      white = Color(0xFFEAEDEF),
      muted = Color(0xFFABB8C0),
      warn = Color(0xFFD59C89);
  late final repository = LoadingInvoiceRepository(widget.owner);
  final picker = ImagePicker();
  LoadingInvoice invoice = LoadingInvoice.empty();
  List<LoadingInvoice> history = [];
  bool busy = true, showHistory = false;
  String? error;
  String activity = 'Загрузка…';
  bool get review => invoice.stage == 'review';
  bool get loading => invoice.stage == 'loading';
  bool get completed => invoice.stage == 'completed';
  String kg(double v) => _fmt1(v);
  @override
  void initState() {
    super.initState();
    restore();
  }

  Future<void> restore() async {
    try {
      history = await repository.load();
      final pending = await repository.pending();
      final lost = await picker.retrieveLostData();
      if (lost.exception != null) throw lost.exception!;
      if (lost.files?.isNotEmpty == true) {
        invoice =
            history.where((i) => i.invoiceId == pending).firstOrNull ??
            LoadingInvoice.empty();
        for (final f in lost.files!) {
          invoice.photos = [
            ...invoice.photos,
            await repository.keepPhoto(f.path, invoice.invoiceId),
          ];
        }
        await repository.save(invoice);
        await repository.setPending(null);
      } else {
        invoice =
            history.where((i) => i.stage != 'completed').firstOrNull ??
            LoadingInvoice.empty();
      }
    } catch (e) {
      error = 'Не удалось открыть накладные: $e';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> perform(String label, Future<void> Function() task) async {
    if (busy) return;
    setState(() {
      busy = true;
      activity = label;
      error = null;
    });
    try {
      await task();
    } catch (e) {
      if (mounted) error = 'Не удалось выполнить действие: $e';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> commit(LoadingInvoice next) async {
    await repository.save(next);
    if (mounted) setState(() => invoice = next);
  }

  Future<void> pick(bool camera) => perform('Добавление фото…', () async {
    await repository.save(invoice);
    await repository.setPending(invoice.invoiceId);
    final files = camera
        ? [await picker.pickImage(source: ImageSource.camera)]
              .whereType<XFile>()
              .toList()
        : await picker.pickMultiImage();
    final next = invoice.copy();
    for (final f in files) {
      next.photos.add(await repository.keepPhoto(f.path, next.invoiceId));
    }
    await commit(next);
    await repository.setPending(null);
  });
  Future<void> recognize() => perform('Распознавание…', () async {
    final result = await widget.recognition.recognize(
      invoiceId: invoice.invoiceId,
      photoPaths: List.unmodifiable(invoice.photos),
    );
    final next = invoice.copy()
      ..items = result.items
      ..statedWeightKg = result.statedWeightKg
      ..mock = result.isMock
      ..stage = 'review';
    await commit(next);
  });
  Future<void> editTotal() async {
    final c = TextEditingController(
      text: invoice.statedWeightKg?.toString() ?? '',
    );
    final value = await showDialog<double>(
      context: context,
      builder: (d) => _KeyboardAlertDialog(
        alignment: Alignment.topCenter,
        scrollable: true,
        backgroundColor: const Color(0xFF11191D),
        title: const Text('Вес в накладной, кг'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(c.text.replaceAll(',', '.'));
              if (v != null && v.isFinite && v > 0) Navigator.pop(d, v);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    // Dispose after the dialog's closing transition releases the text field.
    Future<void>.delayed(const Duration(milliseconds: 300), c.dispose);
    if (value != null && mounted)
      await perform(
        'Сохранение…',
        () => commit(invoice.copy()..statedWeightKg = value),
      );
  }

  Future<void> editItem([LoadingInvoiceItem? item]) async {
    final result = await showDialog<LoadingInvoiceItem>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LoadingItemDialog(item: item),
    );
    if (result == null || !mounted) return;
    await perform('Сохранение…', () async {
      final next = invoice.copy();
      final at = next.items.indexWhere((i) => i.itemId == result.itemId);
      if (at < 0) {
        next.items.add(result);
      } else {
        next.items[at] = result;
      }
      await commit(next);
    });
  }

  Future<bool> confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          backgroundColor: const Color(0xFF11191D),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> finish() async {
    final remaining = invoice.items.length - invoice.loadedItems;
    if (remaining > 0) {
      if (!await confirm(
        'Остались позиции',
        'Не загружено: $remaining позиций, ${invoice.bags - invoice.loadedBags} мешков, ${kg(invoice.weight - invoice.loadedWeight)} кг. Сохранить с этими отметками?',
        'Завершить частично',
      ))
        return;
    }
    if (!mounted) return;
    await perform(
      'Сохранение…',
      () => commit(
        invoice.copy()
          ..stage = 'completed'
          ..completedAt = DateTime.now(),
      ),
    );
  }

  // Same surface and palette as tripScreen/fuelScreen, in logical pixels.
  BoxDecoration entryPanel({bool active = false}) => BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: active ? gold : const Color(0xFF52616A)),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: active
          ? const [Color(0xDB553416), Color(0xE00B1014), Color(0xDB492908)]
          : const [Color(0xC0101D25), Color(0xDB080F14)],
    ),
  );

  Widget panel(Widget child) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: entryPanel(),
    child: child,
  );
  Widget line(String label, String value, {Color color = white}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: muted, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
  Widget action(String label, VoidCallback? tap, {IconData? icon}) =>
      TextButton.icon(
        onPressed: busy ? null : tap,
        style: TextButton.styleFrom(
          foregroundColor: gold,
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: const Color(0xC0101D25),
          side: const BorderSide(color: Color(0xFF52616A)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        ),
        icon: Icon(icon ?? Icons.chevron_right, size: 21),
        label: Text(label),
      );
  void viewPhoto(String path) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (c) => Scaffold(
        backgroundColor: const Color(0xFF0A1014),
        appBar: AppBar(
          title: const Text('Фото накладной'),
          backgroundColor: const Color(0xFF11191D),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Image.file(
              File(path),
              errorBuilder: (_, e, s) => const Text('Фото недоступно'),
            ),
          ),
        ),
      ),
    ),
  );
  Widget photos() => SizedBox(
    height: 104,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: invoice.photos.length,
      separatorBuilder: (_, i) => const SizedBox(width: 8),
      itemBuilder: (c, i) => Stack(
        children: [
          InkWell(
            onTap: () => viewPhoto(invoice.photos[i]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.file(
                File(invoice.photos[i]),
                width: 82,
                height: 104,
                fit: BoxFit.cover,
                cacheWidth: 200,
                errorBuilder: (_, e, s) => const SizedBox(
                  width: 82,
                  child: Icon(Icons.broken_image, color: muted),
                ),
              ),
            ),
          ),
          if (invoice.stage == 'photos')
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                onPressed: busy
                    ? null
                    : () => perform('Сохранение…', () async {
                        final next = invoice.copy()..photos.removeAt(i);
                        await commit(next);
                      }),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close, size: 18),
              ),
            ),
        ],
      ),
    ),
  );
  Widget itemRow(LoadingInvoiceItem item, int index) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: entryPanel(),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: busy || completed
            ? null
            : review
            ? () => editItem(item)
            : () async {
                HapticFeedback.lightImpact();
                await perform('Сохранение…', () async {
                  final next = invoice.copy();
                  next.items[index].isLoaded = !item.isLoaded;
                  await commit(next);
                });
              },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Icon(
                item.isLoaded
                    ? Icons.check_circle_outline
                    : review && item.mismatch
                    ? Icons.error_outline
                    : Icons.radio_button_unchecked,
                color: item.isLoaded
                    ? muted
                    : review && item.mismatch
                    ? warn
                    : gold,
                size: 23,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: item.isLoaded ? muted : white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${kg(item.unitWeightKg)} кг · ${item.bagsCount} мешков · ${kg(item.calculatedWeightKg)} кг',
                      style: const TextStyle(fontSize: 13, color: muted),
                    ),
                    if (review && item.mismatch)
                      Text(
                        'Проверьте: в позиции ${kg(item.totalWeightKg)} кг, по расчёту ${kg(item.calculatedWeightKg)} кг',
                        style: const TextStyle(fontSize: 12, color: warn),
                      ),
                  ],
                ),
              ),
              if (review)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 21,
                    color: muted,
                  ),
                  onPressed: busy
                      ? null
                      : () async {
                          if (!await confirm(
                                'Удалить позицию?',
                                item.name,
                                'Удалить',
                              ) ||
                              !mounted)
                            return;
                          await perform('Сохранение…', () async {
                            final next = invoice.copy()..items.removeAt(index);
                            await commit(next);
                          });
                        },
                ),
            ],
          ),
        ),
      ),
    ),
  );
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
        backgroundColor: const Color(0xFF0B1115),
        body: Stack(
          children: [
            const Positioned.fill(
              child: RepaintBoundary(
                child: _ExtendedArtwork(
                  asset: 'assets/images/scenes/trip_entry.png',
                  topInset: 0,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  MediaQuery.sizeOf(context).width * 74 / 864,
                  8,
                  MediaQuery.sizeOf(context).width * 70 / 864,
                  math.max(12.0, MediaQuery.sizeOf(context).width * 70 / 864),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xD5081117),
                            side: const BorderSide(color: gold),
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: busy
                              ? null
                              : () {
                                  if (showHistory) {
                                    setState(() => showHistory = false);
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                          icon: const Icon(Icons.arrow_back, color: gold),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.receipt_long_outlined,
                          color: gold,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            showHistory
                                ? 'Накладные'
                                : invoice.stage == 'photos'
                                ? 'Добавить накладную'
                                : review
                                ? 'Проверка накладной'
                                : completed
                                ? 'Накладная сохранена'
                                : 'Погрузка',
                            style: const TextStyle(
                              color: white,
                              fontSize: 20,
                              height: 1.15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'История накладных',
                          onPressed: busy
                              ? null
                              : () => perform('Загрузка…', () async {
                                  history = await repository.load();
                                  showHistory = true;
                                }),
                          icon: const Icon(Icons.history, color: gold),
                        ),
                      ],
                    ),
                    Center(
                      child: Container(width: 140, height: 1, color: gold),
                    ),
                    SizedBox(
                      height: math.max(
                        12.0,
                        math.min(
                              MediaQuery.sizeOf(context).width * 538 / 864,
                              MediaQuery.sizeOf(context).height * .35,
                            ) -
                            MediaQuery.paddingOf(context).top -
                            83,
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          error!,
                          style: const TextStyle(color: warn),
                        ),
                      ),
                    if (busy && activity != 'Сохранение…')
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: gold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              activity,
                              style: const TextStyle(color: muted),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: showHistory
                          ? ListView(
                              children: [
                                action('Новая накладная', () {
                                  setState(() {
                                    invoice = LoadingInvoice.empty();
                                    showHistory = false;
                                  });
                                }, icon: Icons.add),
                                if (history.isEmpty)
                                  panel(
                                    const Text(
                                      'Сохранённых накладных пока нет',
                                      style: TextStyle(color: muted),
                                    ),
                                  ),
                                for (final doc in history)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: DecoratedBox(
                                      decoration: entryPanel(),
                                      child: ListTile(
                                        onTap: busy
                                            ? null
                                            : () => setState(() {
                                                invoice = doc.copy();
                                                showHistory = false;
                                              }),
                                        title: Text(
                                          '${_detailDate(doc.createdAt)} ${doc.createdAt.year} · ${_detailTime(doc.createdAt)}',
                                          style: const TextStyle(color: white),
                                        ),
                                        subtitle: Text(
                                          '${doc.stage == 'completed' ? 'Завершена' : 'Черновик'} · ${doc.loadedItems}/${doc.items.length} позиций · ${kg(doc.weight)} кг${doc.mock ? ' · MOCK' : ''}',
                                          style: const TextStyle(color: muted),
                                        ),
                                        trailing: const Icon(
                                          Icons.chevron_right,
                                          color: gold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Column(
                              children: [
                                if (loading || completed)
                                  panel(
                                    Column(
                                      children: [
                                        line(
                                          'Позиций',
                                          '${invoice.loadedItems} из ${invoice.items.length}',
                                        ),
                                        line(
                                          'Мешков',
                                          '${invoice.loadedBags} из ${invoice.bags}',
                                        ),
                                        line(
                                          'Вес',
                                          '${kg(invoice.loadedWeight)} из ${kg(invoice.weight)} кг',
                                          color: gold,
                                        ),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          value: invoice.items.isEmpty
                                              ? 0
                                              : invoice.loadedItems /
                                                    invoice.items.length,
                                          minHeight: 4,
                                          color: gold,
                                          backgroundColor: const Color(
                                            0xFF303639,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Expanded(
                                  child: ListView(
                                    children: [
                                      if (invoice.mock)
                                        panel(
                                          const Text(
                                            'Демонстрация: ИИ ещё не подключён. Это пример данных, а не результат чтения вашего фото. Перед погрузкой замените позиции на реальные.',
                                            style: TextStyle(
                                              color: warn,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      if (invoice.stage == 'photos') ...[
                                        panel(
                                          const Text(
                                            'Добавьте все страницы накладной. Можно сделать несколько снимков или выбрать фото из галереи.',
                                            style: TextStyle(
                                              color: muted,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        if (invoice.photos.isNotEmpty)
                                          panel(photos()),
                                        panel(
                                          Column(
                                            children: [
                                              action(
                                                'Сфотографировать страницу',
                                                () => pick(true),
                                                icon: Icons.camera_alt_outlined,
                                              ),
                                              action(
                                                'Выбрать из галереи',
                                                () => pick(false),
                                                icon: Icons
                                                    .photo_library_outlined,
                                              ),
                                            ],
                                          ),
                                        ),
                                        panel(
                                          const Text(
                                            'Распознавание пока работает в демонстрационном режиме. Фото на сервер не отправляются.',
                                            style: TextStyle(
                                              color: muted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        action(
                                          'Ввести товары вручную',
                                          () => perform(
                                            'Сохранение…',
                                            () => commit(
                                              invoice.copy()..stage = 'review',
                                            ),
                                          ),
                                          icon: Icons.edit_outlined,
                                        ),
                                      ] else ...[
                                        if (review)
                                          panel(
                                            Column(
                                              children: [
                                                line(
                                                  'Найдено позиций',
                                                  '${invoice.items.length}',
                                                ),
                                                line(
                                                  'Всего мешков',
                                                  '${invoice.bags}',
                                                ),
                                                line(
                                                  'Вес по данным позиций',
                                                  '${kg(invoice.recognizedWeight)} кг',
                                                ),
                                                InkWell(
                                                  onTap: busy
                                                      ? null
                                                      : editTotal,
                                                  child: line(
                                                    'Вес в накладной ✎',
                                                    invoice.statedWeightKg ==
                                                            null
                                                        ? 'Указать'
                                                        : '${kg(invoice.statedWeightKg!)} кг',
                                                    color: gold,
                                                  ),
                                                ),
                                                line(
                                                  'Расчётный вес',
                                                  '${kg(invoice.weight)} кг',
                                                  color: invoice.totalMismatch
                                                      ? warn
                                                      : gold,
                                                ),
                                                if (invoice.totalMismatch)
                                                  const Text(
                                                    'Общий вес не сходится. Проверьте позиции и итог на фото.',
                                                    style: TextStyle(
                                                      color: warn,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        if (invoice.photos.isNotEmpty)
                                          panel(
                                            ExpansionTile(
                                              tilePadding: EdgeInsets.zero,
                                              title: Text(
                                                'Исходные фото · ${invoice.photos.length}',
                                                style: const TextStyle(
                                                  color: muted,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              iconColor: gold,
                                              collapsedIconColor: gold,
                                              children: [photos()],
                                            ),
                                          ),
                                        if (completed)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: Text(
                                              '${_detailDate(invoice.createdAt)} ${invoice.createdAt.year} · ${_detailTime(invoice.createdAt)}',
                                              style: const TextStyle(
                                                color: muted,
                                              ),
                                            ),
                                          ),
                                        for (
                                          var i = 0;
                                          i < invoice.items.length;
                                          i++
                                        )
                                          itemRow(invoice.items[i], i),
                                        if (review)
                                          action(
                                            'Добавить позицию',
                                            () => editItem(),
                                            icon: Icons.add,
                                          ),
                                        if (loading)
                                          action(
                                            'Исправить позиции',
                                            () => perform(
                                              'Сохранение…',
                                              () => commit(
                                                invoice.copy()
                                                  ..stage = 'review',
                                              ),
                                            ),
                                            icon: Icons.edit_outlined,
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                                panel(
                                  invoice.stage == 'photos'
                                      ? action(
                                          'Распознать · демо',
                                          invoice.photos.isEmpty
                                              ? null
                                              : recognize,
                                          icon: Icons.document_scanner_outlined,
                                        )
                                      : review
                                      ? action(
                                          'Начать погрузку',
                                          !invoice.ready
                                              ? null
                                              : () => perform(
                                                  'Сохранение…',
                                                  () => commit(
                                                    invoice.copy()
                                                      ..stage = 'loading',
                                                  ),
                                                ),
                                          icon: Icons.local_shipping_outlined,
                                        )
                                      : loading
                                      ? action(
                                          'Загрузка завершена',
                                          finish,
                                          icon: Icons.check_circle_outline,
                                        )
                                      : action(
                                          'Новая накладная',
                                          () => setState(
                                            () => invoice =
                                                LoadingInvoice.empty(),
                                          ),
                                          icon: Icons.add,
                                        ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LoadingItemDialog extends StatefulWidget {
  final LoadingInvoiceItem? item;
  const _LoadingItemDialog({this.item});
  @override
  State<_LoadingItemDialog> createState() => _LoadingItemDialogState();
}

class _LoadingItemDialogState extends State<_LoadingItemDialog> {
  late final name = TextEditingController(text: widget.item?.name ?? '');
  late final unit = TextEditingController(
    text: widget.item?.unitWeightKg.toString() ?? '',
  );
  late final bags = TextEditingController(
    text: widget.item?.bagsCount.toString() ?? '',
  );
  late final total = TextEditingController(
    text: widget.item?.totalWeightKg.toString() ?? '',
  );
  String? error;
  double? number(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.'));
  @override
  void dispose() {
    name.dispose();
    unit.dispose();
    bags.dispose();
    total.dispose();
    super.dispose();
  }

  Widget field(TextEditingController c, String label, {bool text = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          keyboardType: text
              ? TextInputType.text
              : const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, isDense: true),
          onChanged: (_) => setState(() {
            if (c == unit || c == bags) {
              final u = number(unit), n = int.tryParse(bags.text);
              if (u != null && u.isFinite && n != null)
                total.text = (u * n).toString();
            }
          }),
        ),
      );
  @override
  Widget build(BuildContext context) => _KeyboardAlertDialog(
    alignment: Alignment.topCenter,
    scrollable: true,
    backgroundColor: const Color(0xFF11191D),
    title: Text(widget.item == null ? 'Добавить позицию' : 'Проверить позицию'),
    content: SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          field(name, 'Наименование', text: true),
          field(unit, 'Вес упаковки, кг'),
          field(bags, 'Количество мешков'),
          field(total, 'Вес позиции в накладной, кг'),
          TextButton(
            onPressed: () {
              final v = number(unit);
              final n = int.tryParse(bags.text);
              if (v != null && n != null)
                setState(() => total.text = (v * n).toString());
            },
            child: Text(
              'Подставить расчёт: ${_fmt1((number(unit) ?? 0) * (int.tryParse(bags.text) ?? 0))} кг',
            ),
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Color(0xFFD59C89))),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Отмена'),
      ),
      TextButton(
        onPressed: () {
          final i = LoadingInvoiceItem(
            itemId: widget.item?.itemId ?? invoiceEntityId(),
            name: name.text.trim(),
            unitWeightKg: number(unit) ?? double.nan,
            bagsCount: int.tryParse(bags.text) ?? 0,
            totalWeightKg: number(total) ?? double.nan,
            isLoaded: false,
          );
          if (!i.valid) {
            setState(
              () => error = 'Введите название, положительные веса и целое количество мешков',
            );
            return;
          }
          Navigator.pop(context, i);
        },
        child: const Text('Сохранить'),
      ),
    ],
  );
}
