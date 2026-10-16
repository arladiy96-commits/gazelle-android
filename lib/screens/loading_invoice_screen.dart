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
  }) => ServerInvoiceRecognitionService().recognize(
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
  String? recognitionNotice;
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
  Future<void> returnToPhotos() => perform(
    'Возврат к фото…',
    () => commit(invoice.copy()..stage = 'photos'),
  );

  Future<void> recognize() async {
    if (busy) return;
    if (invoice.items.isNotEmpty &&
        !await confirm(
          'Распознать заново?',
          'После успешного распознавания текущие позиции и отметки загрузки заменятся результатом ИИ.',
          'Распознать',
        ))
      return;
    if (!mounted) return;
    await perform('Распознавание…', () async {
      final result = await widget.recognition.recognize(
        invoiceId: invoice.invoiceId,
        photoPaths: List.unmodifiable(invoice.photos),
      );
      recognitionNotice = result.warnings.isEmpty
          ? null
          : result.warnings.join("\n");
      final next = invoice.copy()
        ..items = result.items
        ..statedWeightKg = result.statedWeightKg
        ..mock = result.isMock
        ..stage = 'review';
      await commit(next);
    });
  }

  Widget totalInput() => InlineValueInput(
    value: invoice.statedWeightKg == null ? '' : kg(invoice.statedWeightKg!),
    label: 'Вес в накладной, кг',
    enabled: !busy,
    save: (text) async {
      final value = double.tryParse(text.replaceAll(',', '.'));
      if (value == null || !value.isFinite || value <= 0)
        throw ArgumentError('Введите вес больше нуля');
      await perform(
        'Сохранение…',
        () => commit(invoice.copy()..statedWeightKg = value),
      );
    },
  );

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
  Future<void> toggleLoaded(LoadingInvoiceItem item) async {
    if (busy || !loading) return;
    HapticFeedback.lightImpact();
    await perform('Сохранение…', () async {
      final next = invoice.copy();
      final at = next.items.indexWhere((i) => i.itemId == item.itemId);
      if (at < 0) return;
      next.items[at].isLoaded = !next.items[at].isLoaded;
      await commit(next);
    });
  }

  String bagLabel(int count) {
    final last = count % 10, lastTwo = count % 100;
    if (lastTwo >= 11 && lastTwo <= 14) return 'мешков';
    if (last == 1) return 'мешок';
    if (last >= 2 && last <= 4) return 'мешка';
    return 'мешков';
  }

  Widget loadingChecklist(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final top = MediaQuery.paddingOf(context).top;
    final heroHeight = math.max(top + 80.0, width * .33);
    Widget roundButton(IconData icon, String label, VoidCallback tap) =>
        IconButton(
          tooltip: label,
          onPressed: busy ? null : tap,
          style: IconButton.styleFrom(
            foregroundColor: gold,
            backgroundColor: const Color(0xB3081015),
            side: const BorderSide(color: gold),
            minimumSize: const Size(44, 44),
          ),
          icon: Icon(icon, size: 25),
        );
    return Column(
      children: [
        SizedBox(
          height: heroHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/scenes/loading_warehouse.png',
                  fit: BoxFit.cover, alignment: Alignment.bottomCenter),
              const DecoratedBox(decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xA6000000), Color(0x00000000), Color(0x7002090D)],
                  stops: [0, .65, 1],
                ),
              )),
              Positioned(
                left: 12, right: 12, top: top + 6,
                child: Row(children: [
                  roundButton(Icons.arrow_back, 'Назад', () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  const Icon(Icons.assignment_outlined, color: gold, size: 34),
                  const SizedBox(width: 8),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Погрузка', style: TextStyle(
                        color: white, fontSize: 24, height: 1.1,
                        fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      const Text('Отметьте загруженный товар', style: TextStyle(
                        color: white, fontSize: 12, height: 1.1)),
                    ],
                  )),
                  roundButton(Icons.history, 'История накладных', () =>
                    perform('Загрузка…', () async {
                      history = await repository.load();
                      showHistory = true;
                    })),
                ]),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(padding: const EdgeInsets.all(8),
            child: Text(error!, style: const TextStyle(color: warn))),
        Expanded(
          child: Scrollbar(
            child: ListView.builder(
              key: PageStorageKey('loading-${invoice.invoiceId}'),
              padding: const EdgeInsets.fromLTRB(9, 2, 9, 4),
              itemCount: invoice.items.length,
              itemBuilder: (context, index) {
                final item = invoice.items[index];
                return Padding(
                  key: ValueKey(item.itemId),
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Semantics(
                    checked: item.isLoaded,
                    label: '${item.name}, ${item.bagsCount} ${bagLabel(item.bagsCount)}',
                    child: CustomPaint(
                      painter: _LoadingMetalPainter(active: item.isLoaded),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: busy ? null : () => toggleLoaded(item),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 50),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
                              child: Row(children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: item.isLoaded ? const Color(0xFFFFB13F) : const Color(0xFF071017),
                                    border: Border.all(
                                      color: item.isLoaded ? const Color(0xFFEAA23C) : const Color(0xFF75818A),
                                      width: 1.4),
                                    boxShadow: item.isLoaded ? const [BoxShadow(
                                      color: Color(0x305F390B), blurRadius: 8)] : null,
                                  ),
                                  child: item.isLoaded ? const Icon(Icons.check,
                                    color: Color(0xFF15150E), size: 22) : null,
                                ),
                                Container(width: 1, height: 30,
                                  margin: const EdgeInsets.symmetric(horizontal: 12),
                                  color: const Color(0x405F6C72)),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(
                                      color: white, fontSize: 15, height: 1.15,
                                      fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text('${kg(item.unitWeightKg)} кг · ${item.bagsCount} ${bagLabel(item.bagsCount)}',
                                      style: const TextStyle(color: Color(0xFF9EA6AC),
                                        fontSize: 12, height: 1.1)),
                                  ],
                                )),
                                IconButton(
                                  tooltip: 'Сведения о товаре',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
                                  onPressed: busy ? null : () => showModalBottomSheet<void>(
                                    context: context,
                                    backgroundColor: const Color(0xFF0D171D),
                                    builder: (sheetContext) => SafeArea(
                                      child: Padding(padding: const EdgeInsets.all(20),
                                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                                          Text(item.name, style: const TextStyle(color: white, fontSize: 20)),
                                          const SizedBox(height: 12),
                                          line('Мешков', '${item.bagsCount}'),
                                          line('Вес мешка', '${kg(item.unitWeightKg)} кг'),
                                          line('Общий вес', '${kg(item.calculatedWeightKg)} кг'),
                                          action('Исправить позиции', () {
                                            Navigator.pop(sheetContext);
                                            perform('Сохранение…', () => commit(invoice.copy()..stage = 'review'));
                                          }, icon: Icons.edit_outlined),
                                          if (invoice.photos.isNotEmpty) photos(),
                                        ]),
                                      ),
                                    ),
                                  ),
                                  icon: Icon(Icons.chevron_right, size: 27,
                                    color: item.isLoaded ? gold : const Color(0xFF89959D)),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SafeArea(top: false, minimum: const EdgeInsets.fromLTRB(8, 3, 8, 8),
          child: Semantics(button: true, label: 'Загрузка завершена',
            child: CustomPaint(
              painter: const _LoadingMetalPainter(active: true, button: true),
              child: Material(color: Colors.transparent,
                child: InkWell(onTap: busy ? null : finish,
                  child: SizedBox(width: double.infinity, height: 62,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.check_circle, color: Color(0xFF171911), size: 32),
                      const SizedBox(width: 12),
                      Flexible(child: Text(busy ? 'Сохранение…' : 'Загрузка завершена',
                        style: const TextStyle(color: Color(0xFF171911), fontSize: 18,
                          fontWeight: FontWeight.w700))),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy && !showHistory && !review,
    onPopInvokedWithResult: (didPop, result) {
      if (didPop || busy) return;
      if (showHistory) {
        setState(() => showHistory = false);
      } else if (review) {
        returnToPhotos();
      }
    },
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
        body: loading && !showHistory ? loadingChecklist(context) : Stack(
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
                                  } else if (review) {
                                    returnToPhotos();
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
                                      if (recognitionNotice != null)
                                        panel(
                                          Text(
                                            recognitionNotice!,
                                            style: const TextStyle(
                                              color: warn,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
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
                                            'Фото отправляются на ваш сервер для распознавания. Перед погрузкой проверьте товары, количество мешков и вес.',
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
                                          action(
                                            'Вернуться к фото и сканированию',
                                            returnToPhotos,
                                            icon:
                                                Icons.document_scanner_outlined,
                                          ),
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
                                                totalInput(),
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
                                          'Распознать через ИИ',
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
        child: KeyboardInput(
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

// Chamfered steel edging is painted at the actual row size; text stays native.
class _LoadingMetalPainter extends CustomPainter {
  final bool active, button;
  const _LoadingMetalPainter({required this.active, this.button = false});

  Path outline(Rect r, double cut) => Path()
    ..moveTo(r.left + cut, r.top)
    ..lineTo(r.right - cut, r.top)
    ..lineTo(r.right, r.top + cut)
    ..lineTo(r.right, r.bottom - cut)
    ..lineTo(r.right - cut, r.bottom)
    ..lineTo(r.left + cut, r.bottom)
    ..lineTo(r.left, r.bottom - cut)
    ..lineTo(r.left, r.top + cut)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = outline(rect.deflate(1), 7);
    canvas.drawPath(outer, Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF647079), Color(0xFF131B21), Color(0xFF394751), Color(0xFF0A0F13)],
      stops: [0, .2, .8, 1],
    ).createShader(rect));
    final inner = outline(rect.deflate(3), 5);
    canvas.drawPath(inner, Paint()..shader = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: button
        ? const [Color(0xFFFFC46C), Color(0xFFE59628), Color(0xFFC77717), Color(0xFFF6AD45)]
        : active
          ? const [Color(0xFF382A18), Color(0xFF101719), Color(0xFF0A1116), Color(0xFF382919)]
          : const [Color(0xFF101E27), Color(0xFF071219), Color(0xFF09151C)],
    ).createShader(rect));
    canvas.drawPath(inner, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = active ? const Color(0xFFBE9358) : const Color(0xFF52616C));
    canvas.drawLine(Offset(10, 5), Offset(size.width - 10, 5),
      Paint()..color = active ? const Color(0x55FFE0A5) : const Color(0x305D808F));
    if (button) {
      // Fine brushed-metal grain, stable across redraws.
      canvas.save();
      canvas.clipPath(inner);
      final random = math.Random(37);
      final grain = Paint()..strokeWidth = .45;
      for (var i = 0; i < size.width * 2; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        grain.color = i.isEven ? const Color(0x18FFF0C5) : const Color(0x147A3E09);
        canvas.drawLine(Offset(x, y), Offset(x + random.nextDouble() * 8 + 1, y), grain);
      }
      canvas.restore();
      for (final x in [11.0, size.width - 11]) {
        for (final y in [11.0, size.height - 11]) {
          canvas.drawCircle(Offset(x, y), 3.8, Paint()..color = const Color(0xFF111C22));
          canvas.drawCircle(Offset(x, y), 2.2, Paint()..color = const Color(0xFF5F6970));
          canvas.drawLine(Offset(x - 1, y + 1), Offset(x + 1, y - 1),
            Paint()..color = const Color(0xFF131B20)..strokeWidth = 1);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LoadingMetalPainter oldDelegate) =>
      oldDelegate.active != active || oldDelegate.button != button;
}
